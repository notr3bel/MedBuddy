import requests
import os

key = os.getenv("AZURE_TRANSLATOR_KEY")
endpoint = os.getenv("AZURE_TRANSLATOR_ENDPOINT", "https://api.cognitive.microsofttranslator.com/")

location = "eastus"

def translate_text(text, target_language):

    path = '/translate?api-version=3.0'

    params = f'&to={target_language}'

    constructed_url = endpoint + path + params

    headers = {
        'Ocp-Apim-Subscription-Key': key,
        'Ocp-Apim-Subscription-Region': location,
        'Content-type': 'application/json'
    }

    body = [{
        'text': text
    }]

    response = requests.post(constructed_url, headers=headers, json=body)

    result = response.json()

    return result[0]["translations"][0]["text"]