from pydantic import BaseModel

class BasicResponse(BaseModel):
    success: bool
    message: str
