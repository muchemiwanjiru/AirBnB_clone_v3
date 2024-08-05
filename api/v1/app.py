#!/usr/bin/python3
"""Main entry point of API"""

from flask import Flask, jsonify, make_response
from models import storage
from api.v1.views import app_views
import os
from flask_cors import CORS

app = Flask(__name__)
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True

app.register_blueprint(app_views, url_prefix='/api/v1')
CORS(app, origins="0.0.0.0")


@app.teardown_appcontext
def teardown_db(exception):
    """Close storage"""
    storage.close()


@app.errorhandler(404)
def not_found(error):
    """Handler for 404 errors, returns JSON response"""
    return make_response(jsonify({"error": "Not found"}), 404)


if __name__ == "__main__":
    host = os.getenv('HBNB_API_HOST', '0.0.0.0')
    port = os.getenv('HBNB_API_PORT', '5000')
    app.run(host=host, port=port, threaded=True)
