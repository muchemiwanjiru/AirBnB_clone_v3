#!/usr/bin/python3
"""
Place-Amenity API module
"""
from flask import jsonify, request, abort, make_response
from api.v1.views import app_views
from models import storage
from models.place import Place
from models.amenity import Amenity


@app_views.route('/places/<place_id>/amenities',
                 methods=['GET'], strict_slashes=False)
def get_amenities_of_place(place_id):
    """Retrieves the list of all Amenity objects of a Place"""
    place = storage.get(Place, place_id)
    if not place:
        abort(404)
    amenities = [amenity.to_dict() for amenity in place.amenities]
    return jsonify(amenities)


@app_views.route('/places/<place_id>/amenities/<amenity_id>',
                 methods=['POST'], strict_slashes=False)
def link_amenity_to_place(place_id, amenity_id):
    """Links an Amenity object to a Place"""
    place = storage.get(Place, place_id)
    if not place:
        abort(404)
    amenity = storage.get(Amenity, amenity_id)
    if not amenity:
        abort(404)

    if storage.__class__.__name__ == 'DBStorage':
        if amenity in place.amenities:
            return jsonify(amenity.to_dict()), 200
        place.amenities.append(amenity)
        storage.save()
    elif storage.__class__.__name__ == 'FileStorage':
        if amenity_id in place.amenity_ids:
            return jsonify(amenity.to_dict()), 200
        place.amenity_ids.append(amenity_id)
        storage.save()

    return make_response(jsonify(amenity.to_dict()), 201)


@app_views.route('/places/<place_id>/amenities/<amenity_id>',
                 methods=['DELETE'], strict_slashes=False)
def unlink_amenity_from_place(place_id, amenity_id):
    """Deletes an Amenity object from a Place"""
    place = storage.get(Place, place_id)
    if not place:
        abort(404)
    amenity = storage.get(Amenity, amenity_id)
    if not amenity:
        abort(404)

    if storage.__class__.__name__ == 'DBStorage':
        if amenity not in place.amenities:
            abort(404)
        place.amenities.remove(amenity)
        storage.save()
    elif storage.__class__.__name__ == 'FileStorage':
        if amenity_id not in place.amenity_ids:
            abort(404)
        place.amenity_ids.remove(amenity_id)
        storage.save()

    return make_response(jsonify({}), 200)
