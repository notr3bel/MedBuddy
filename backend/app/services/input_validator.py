import io
import logging
from PIL import Image, UnidentifiedImageError
import pypdf
import cv2
import numpy as np

try:
    import pillow_heif
    pillow_heif.register_heif_opener()
except Exception:
    pass

MAX_FILE_SIZE_BYTES = 15 * 1024 * 1024  # 15 MB
MIN_IMAGE_DIMENSION = 300  # 300px
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".pdf", ".bmp", ".tiff", ".heic", ".heif"}

# Limit Decompression Bomb vector
Image.MAX_IMAGE_PIXELS = 25_000_000

def validate_input_file(file_bytes: bytes, filename: str = "") -> dict:
    """
    Phase 1: Validates uploaded file before OCR begins.
    Returns dict: {"valid": bool, "error": str | None, "file_type": str}
    """
    if not file_bytes or len(file_bytes) == 0:
        return {"valid": False, "error": "Empty file uploaded. Please upload a valid document or image.", "file_type": "unknown"}

    if len(file_bytes) > MAX_FILE_SIZE_BYTES:
        return {"valid": False, "error": "File size exceeds maximum limit of 15MB.", "file_type": "unknown"}

    # Check extension / header
    ext = ""
    if filename and "." in filename:
        ext = "." + filename.rsplit(".", 1)[-1].lower()

    # Detect PDF by magic bytes %PDF
    if file_bytes.startswith(b"%PDF") or ext == ".pdf":
        return _validate_pdf(file_bytes)

    return _validate_image(file_bytes)

def _validate_pdf(file_bytes: bytes) -> dict:
    try:
        reader = pypdf.PdfReader(io.BytesIO(file_bytes))
        if reader.is_encrypted:
            return {
                "valid": False,
                "error": "Password protected PDFs are not supported. Please upload an unprotected PDF.",
                "file_type": "pdf"
            }
        if len(reader.pages) == 0:
            return {
                "valid": False,
                "error": "The PDF document has no pages.",
                "file_type": "pdf"
            }
        return {"valid": True, "error": None, "file_type": "pdf"}
    except Exception as e:
        logging.error(f"PDF validation error: {e}")
        return {
            "valid": False,
            "error": "Corrupted or unreadable PDF document.",
            "file_type": "pdf"
        }

def _validate_image(file_bytes: bytes) -> dict:
    try:
        img = Image.open(io.BytesIO(file_bytes))
        img.verify()
        
        # Re-open after verify() because verify() clears internal state
        img = Image.open(io.BytesIO(file_bytes))
        width, height = img.size

        if width < MIN_IMAGE_DIMENSION or height < MIN_IMAGE_DIMENSION:
            return {
                "valid": False,
                "error": f"Extremely small image ({width}x{height}px). Minimum size is {MIN_IMAGE_DIMENSION}x{MIN_IMAGE_DIMENSION}px.",
                "file_type": "image"
            }

        # Convert to numpy array for CV checks
        img_rgb = img.convert("RGB")
        img_np = np.array(img_rgb)
        gray = cv2.cvtColor(img_np, cv2.COLOR_RGB2GRAY)

        mean_val = np.mean(gray)
        std_val = np.std(gray)

        # Check completely white / blank image (must have both extremely high brightness AND almost zero variance)
        if (mean_val > 248 and std_val < 6) or (mean_val > 235 and std_val < 3):
            return {
                "valid": False,
                "error": "Image is completely white or blank. Please capture a clear medical document.",
                "file_type": "image"
            }

        # Check completely black image (must have both extremely low brightness AND almost zero variance)
        if (mean_val < 15 and std_val < 6) or (mean_val < 25 and std_val < 3):
            return {
                "valid": False,
                "error": "Image is completely black or dark. Please capture a clear medical document.",
                "file_type": "image"
            }

        # Blur pre-check via Laplacian variance
        laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
        if laplacian_var < 40:
            return {
                "valid": False,
                "error": "Extremely blurry image detected. Please capture a clear, focused photo.",
                "file_type": "image"
            }

        return {"valid": True, "error": None, "file_type": "image"}

    except UnidentifiedImageError:
        return {
            "valid": False,
            "error": "Unsupported or corrupted image format.",
            "file_type": "unknown"
        }
    except Exception as e:
        logging.error(f"Image validation exception: {e}")
        return {
            "valid": False,
            "error": "Corrupted or unreadable image file.",
            "file_type": "unknown"
        }
