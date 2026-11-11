import io
import logging
from PIL import Image, ImageOps
import pypdf
import pypdfium2

try:
    import pillow_heif
    pillow_heif.register_heif_opener()
except Exception:
    pass

def prepare_input_for_analysis(file_bytes: bytes, filename: str = "") -> dict:
    """
    Converts and normalizes incoming files (PNG, JPG, HEIC, HEIF, PDF, WEBP, BMP, TIFF)
    into standardized JPEG image bytes + extracted native PDF text (if applicable).
    
    Returns:
    {
        "image_bytes": bytes,         # Clean JPEG bytes for vision models, OCR, and quality analysis
        "file_type": "pdf" | "image",  # Original category
        "pdf_native_text": str         # Native text extracted from PDF pages (if any)
    }
    """
    if not file_bytes:
        return {"image_bytes": b"", "page_images": [], "file_type": "unknown", "pdf_native_text": ""}

    ext = ""
    if filename and "." in filename:
        ext = "." + filename.rsplit(".", 1)[-1].lower()

    is_pdf = file_bytes.startswith(b"%PDF") or ext == ".pdf"

    if is_pdf:
        return _process_pdf(file_bytes)

    return _process_image(file_bytes)

def _process_pdf(file_bytes: bytes) -> dict:
    native_text_parts = []
    # 1. Extract native text across all PDF pages if available via pypdf
    try:
        reader = pypdf.PdfReader(io.BytesIO(file_bytes))
        for idx, page in enumerate(reader.pages):
            text = page.extract_text()
            if text and text.strip():
                native_text_parts.append(f"--- Page {idx + 1} ---\n{text.strip()}")
    except Exception as e:
        logging.warning(f"pypdf text extraction warning: {e}")

    pdf_native_text = "\n\n".join(native_text_parts).strip()

    # 2. Render PDF pages into individual high-clarity JPEG page images via pypdfium2
    try:
        pdf = pypdfium2.PdfDocument(file_bytes)
        num_pages = len(pdf)
        images = []
        page_images_bytes = []

        # Limit to first 6 pages max to keep memory and latency low
        pages_to_render = min(num_pages, 6)
        for i in range(pages_to_render):
            page = pdf[i]
            # Render at 160 DPI scale for crisp OCR and Vision processing
            pil_image = page.render(scale=160/72).to_pil().convert("RGB")
            if max(pil_image.width, pil_image.height) > 1600:
                pil_image.thumbnail((1600, 1600), Image.Resampling.LANCZOS)
            images.append(pil_image)

            p_buf = io.BytesIO()
            pil_image.save(p_buf, format="JPEG", quality=85, optimize=True)
            page_images_bytes.append(p_buf.getvalue())

        if not images:
            return {"image_bytes": file_bytes, "page_images": [], "file_type": "pdf", "pdf_native_text": pdf_native_text}

        return {
            "image_bytes": page_images_bytes[0],
            "page_images": page_images_bytes,
            "file_type": "pdf",
            "pdf_native_text": pdf_native_text
        }

    except Exception as e:
        logging.error(f"PDF rendering error: {e}")
        return {
            "image_bytes": file_bytes,
            "page_images": [],
            "file_type": "pdf",
            "pdf_native_text": pdf_native_text
        }

def _process_image(file_bytes: bytes) -> dict:
    try:
        pil_img = Image.open(io.BytesIO(file_bytes))
        try:
            pil_img = ImageOps.exif_transpose(pil_img)
        except Exception:
            pass
        
        rgb_img = pil_img.convert("RGB")
        # High-speed payload optimization: resize image so max dimension is 1200px
        if max(rgb_img.width, rgb_img.height) > 1200:
            rgb_img.thumbnail((1200, 1200), Image.Resampling.LANCZOS)

        output_buf = io.BytesIO()
        rgb_img.save(output_buf, format="JPEG", quality=82, optimize=True)
        jpeg_bytes = output_buf.getvalue()

        return {
            "image_bytes": jpeg_bytes,
            "file_type": "image",
            "pdf_native_text": ""
        }
    except Exception as e:
        logging.warning(f"Image normalization fallback: {e}")
        return {
            "image_bytes": file_bytes,
            "file_type": "image",
            "pdf_native_text": ""
        }
