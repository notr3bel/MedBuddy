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
        return {"image_bytes": b"", "file_type": "unknown", "pdf_native_text": ""}

    ext = ""
    if filename and "." in filename:
        ext = "." + filename.rsplit(".", 1)[-1].lower()

    is_pdf = file_bytes.startswith(b"%PDF") or ext == ".pdf"

    if is_pdf:
        return _process_pdf(file_bytes)

    return _process_image(file_bytes)

def _process_pdf(file_bytes: bytes) -> dict:
    native_text_parts = []
    # 1. Extract native text if available via pypdf
    try:
        reader = pypdf.PdfReader(io.BytesIO(file_bytes))
        for page in reader.pages:
            text = page.extract_text()
            if text:
                native_text_parts.append(text)
    except Exception as e:
        logging.warning(f"pypdf text extraction warning: {e}")

    pdf_native_text = "\n".join(native_text_parts).strip()

    # 2. Render PDF pages into a single combined PIL Image via pypdfium2
    try:
        pdf = pypdfium2.PdfDocument(file_bytes)
        num_pages = len(pdf)
        images = []
        
        # Limit to first 5 pages max to avoid memory issues
        pages_to_render = min(num_pages, 5)
        for i in range(pages_to_render):
            page = pdf[i]
            # Render at 200 DPI scale (200/72) for crisp OCR and Vision processing
            pil_image = page.render(scale=200/72).to_pil()
            pil_image = pil_image.convert("RGB")
            images.append(pil_image)

        if not images:
            return {"image_bytes": file_bytes, "file_type": "pdf", "pdf_native_text": pdf_native_text}

        if len(images) == 1:
            combined_image = images[0]
        else:
            # Concatenate pages vertically
            total_width = max(img.width for img in images)
            total_height = sum(img.height for img in images)
            combined_image = Image.new("RGB", (total_width, total_height), (255, 255, 255))
            y_offset = 0
            for img in images:
                combined_image.paste(img, (0, y_offset))
                y_offset += img.height

        output_buf = io.BytesIO()
        combined_image.save(output_buf, format="JPEG", quality=90)
        rendered_bytes = output_buf.getvalue()

        return {
            "image_bytes": rendered_bytes,
            "file_type": "pdf",
            "pdf_native_text": pdf_native_text
        }

    except Exception as e:
        logging.error(f"PDF rendering error: {e}")
        return {
            "image_bytes": file_bytes,
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
