import io
import pytest
from PIL import Image
import pypdf

from app.services.input_validator import validate_input_file
from app.services.file_converter import prepare_input_for_analysis

from PIL import ImageDraw

def create_sample_png_bytes(width=500, height=500):
    img = Image.new("RGB", (width, height), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw.rectangle([50, 50, 450, 450], outline=(0, 0, 0), fill=(200, 200, 200))
    for i in range(100, 400, 20):
        draw.line([i, 100, i, 400], fill=(0, 0, 0), width=2)
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()

def create_sample_jpg_bytes(width=500, height=500):
    img = Image.new("RGB", (width, height), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw.rectangle([50, 50, 450, 450], outline=(0, 0, 0), fill=(200, 200, 200))
    for i in range(100, 400, 20):
        draw.line([i, 100, i, 400], fill=(0, 0, 0), width=2)
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()

def create_sample_pdf_bytes():
    # Create a simple PDF containing an image page
    img = Image.new("RGB", (500, 500), color=(150, 150, 150))
    img_buf = io.BytesIO()
    img.save(img_buf, format="PDF")
    return img_buf.getvalue()

def test_png_validation_and_conversion():
    png_bytes = create_sample_png_bytes()
    val = validate_input_file(png_bytes, "prescription.png")
    assert val["valid"] is True
    
    prep = prepare_input_for_analysis(png_bytes, "prescription.png")
    assert prep["file_type"] == "image"
    assert len(prep["image_bytes"]) > 0

def test_jpg_validation_and_conversion():
    jpg_bytes = create_sample_jpg_bytes()
    val = validate_input_file(jpg_bytes, "report.jpg")
    assert val["valid"] is True

    prep = prepare_input_for_analysis(jpg_bytes, "report.jpg")
    assert prep["file_type"] == "image"
    assert len(prep["image_bytes"]) > 0

def test_pdf_validation_and_conversion():
    pdf_bytes = create_sample_pdf_bytes()
    val = validate_input_file(pdf_bytes, "document.pdf")
    assert val["valid"] is True
    assert val["file_type"] == "pdf"

    prep = prepare_input_for_analysis(pdf_bytes, "document.pdf")
    assert prep["file_type"] == "pdf"
    assert len(prep["image_bytes"]) > 0

def test_heic_extension_allowed():
    # Verify .heic and .heif extensions are allowed in ALLOWED_EXTENSIONS
    from app.services.input_validator import ALLOWED_EXTENSIONS
    assert ".heic" in ALLOWED_EXTENSIONS
    assert ".heif" in ALLOWED_EXTENSIONS
