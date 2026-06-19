import urllib.request
import urllib.parse
import json
import uuid

# We will perform a multipart form-data upload manually or using standard libraries.
# Since we have python, we can use a simpler post request or simulate it.
import http.client
import mimetypes

def post_multipart(host, selector, fields, files):
    content_type, body = encode_multipart_formdata(fields, files)
    h = http.client.HTTPConnection(host)
    headers = {
        'User-Agent': 'Python test',
        'Content-Type': content_type
    }
    h.request('POST', selector, body, headers)
    res = h.getresponse()
    return res.status, res.reason, res.read().decode('utf-8')

def encode_multipart_formdata(fields, files):
    BOUNDARY = '----------ThIs_Is_tHe_boUnDaRy_$'
    CRLF = '\r\n'
    L = []
    for (key, value) in fields:
        L.append('--' + BOUNDARY)
        L.append('Content-Disposition: form-data; name="%s"' % key)
        L.append('')
        L.append(value)
    for (key, filename, value) in files:
        L.append('--' + BOUNDARY)
        L.append('Content-Disposition: form-data; name="%s"; filename="%s"' % (key, filename))
        L.append('Content-Type: %s' % get_content_type(filename))
        L.append('')
        L.append(value)
    L.append('--' + BOUNDARY + '--')
    L.append('')
    body = CRLF.join(L)
    # If body is string, encode it as bytes
    if isinstance(body, str):
        body = body.encode('utf-8')
    content_type = 'multipart/form-data; boundary=%s' % BOUNDARY
    return content_type, body

def get_content_type(filename):
    return mimetypes.guess_type(filename)[0] or 'application/octet-stream'

try:
    status, reason, res_body = post_multipart('127.0.0.1:5000', '/api/upload', [], [('file', 'test_image.png', b'fake png data')])
    print("Status:", status)
    print("Reason:", reason)
    print("Body:", res_body)
except Exception as e:
    print("Error:", e)
