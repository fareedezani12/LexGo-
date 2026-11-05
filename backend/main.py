from database import engine, Base
import models
from fastapi import FastAPI
from database import test_database_connection
from pathlib import Path
from uuid import uuid4
from fastapi import UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
from models import HandwritingSample
from sqlalchemy import desc
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import httpx

app = FastAPI(
    title="LexGo API",
    description="Backend API for LexGo",
    version="1.0.0"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=[],
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


Base.metadata.create_all(bind=engine)


@app.get("/")
def home():
    return {
        "message": "Welcome to LexGo API!",
        "status": "running"
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }


@app.get("/database-test")
def database_test():
    try:
        test_database_connection()
        return {
            "status": "success",
            "message": "Connected to LexGo MySQL database!"
        }
    except Exception as error:
        return {
            "status": "error",
            "message": str(error)
        }


UPLOAD_DIR = Path("uploads/handwriting")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
TROCR_RECOGNIZE_URL = "http://localhost:8001/recognize"


@app.post("/samples/upload")
async def upload_handwriting(
    title: str = Form(...),
    image: UploadFile = File(...)
):
    if image.content_type != "image/png":
        raise HTTPException(
            status_code=400,
            detail="Only PNG images are accepted."
        )

    db: Session = SessionLocal()

    try:
        filename = f"{uuid4().hex}.png"
        file_path = UPLOAD_DIR / filename

        image_data = await image.read()

        if not image_data:
            raise HTTPException(
                status_code=400,
                detail="Uploaded image is empty."
            )

        if len(image_data) > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=413,
                detail="Image must not exceed 10 MB."
            )

        file_path.write_bytes(image_data)

        # Recognize the image before saving the database record.
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    TROCR_RECOGNIZE_URL,
                    files={"file": (filename, image_data, "image/png")}
                )
                response.raise_for_status()
                recognition_result = response.json()
        except httpx.TimeoutException:
            raise HTTPException(
                status_code=504,
                detail="Handwriting recognition service timed out. Please try again."
            )
        except httpx.RequestError:
            raise HTTPException(
                status_code=502,
                detail="Handwriting recognition service is unavailable. Please try again."
            )
        except httpx.HTTPStatusError:
            raise HTTPException(
                status_code=502,
                detail="Handwriting recognition service could not process the image."
            )
        except ValueError:
            raise HTTPException(
                status_code=502,
                detail="Handwriting recognition service returned an invalid response."
            )

        recognized_text = (
            recognition_result.get("recognized_text")
            if isinstance(recognition_result, dict)
            else None
        )
        if not isinstance(recognized_text, str):
            raise HTTPException(
                status_code=502,
                detail="Handwriting recognition service returned an invalid response."
            )

        sample = HandwritingSample(
            title=title,
            image_path=str(file_path),
            recognized_text=recognized_text
        )

        db.add(sample)
        db.flush()
        db.refresh(sample)
        db.commit()

        return {
            "message": "Handwriting saved successfully!",
            "sample_id": sample.id,
            "title": sample.title,
            "image_path": sample.image_path,
            "recognized_text": sample.recognized_text
        }

    except HTTPException:
        db.rollback()

        if "file_path" in locals():
            file_path.unlink(missing_ok=True)

        raise
    except Exception:
        db.rollback()

        if "file_path" in locals():
            file_path.unlink(missing_ok=True)

        raise HTTPException(
            status_code=500,
            detail="Could not save the handwriting sample. Please try again."
        )

    finally:
        db.close()
        await image.close()


@app.get("/samples")
def get_handwriting_samples():
    db = SessionLocal()

    try:
        samples = (
            db.query(HandwritingSample)
            .order_by(desc(HandwritingSample.created_at))
            .all()
        )

        return [
            {
                "id": sample.id,
                "title": sample.title,
                "image_path": sample.image_path,
                "recognized_text": sample.recognized_text,
                "created_at": sample.created_at.isoformat()
                if sample.created_at else None
            }
            for sample in samples
        ]

    finally:
        db.close()


@app.get("/samples/{sample_id}/image")
def get_handwriting_image(sample_id: int):
    db = SessionLocal()

    try:
        sample = db.query(HandwritingSample).filter(
            HandwritingSample.id == sample_id
        ).first()

        if not sample:
            raise HTTPException(
                status_code=404,
                detail="Handwriting sample not found."
            )

        image_path = Path(sample.image_path)

        if not image_path.is_file():
            raise HTTPException(
                status_code=404,
                detail="Image file not found."
            )

        return FileResponse(
            path=image_path,
            media_type="image/png"
        )

    finally:
        db.close()
