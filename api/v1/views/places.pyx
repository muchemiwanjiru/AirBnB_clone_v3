#!/usr/bin/python3
"""
Place API module
"""
from flask import jsonify, request, abort, make_response
from api.v1.views import app_views
from models import storage
from models.city import City
from models.place import Place
from models.user import User
from models.state import State
from models.amenity import Amenity


@app_views.route('/cities/<city_id>/places',
                 methods=['GET'], strict_slashes=False)
def get_places(city_id):
    """Retrieves the list of all Place objects of a City"""
    city = storage.get(City, city_id)
    if not city:
        abort(404)
    places = [place.to_dict() for place in city.places]
    return jsonify(places)


@app_views.route('/places/<place_id>', methods=['GET'], strict_slashes=False)
def get_place(place_id):
    """Retrieves a Place object"""
    place = storage.get(Place, place_id)
    if not place:
        abort(404)
    return jsonify(place.to_dict())


@app_views.route('/places/<place_id>',
                 methods=['DELETE'], strict_slashes=False)
def delete_place(place_id):
    """Deletes a Place object"""
    place = storage.get(Place, place_id)
    if not place:
        abort(404)
    storage.delete(place)
    storage.save()
    return make_response(jsonify({}), 200)


@app_views.route('/cities/<city_id>/places',
                 methods=['POST'], strict_slashes=False)
def create_place(city_id):
    """Creates a Place"""
    city = storage.get(City, city_id)
    if not city:
        abort(404)
    if not request.is_json:
        abort(400, description="Not a JSON")
    data = request.get_json()
    if 'user_id' not in data:
        abort(400, description="Missing user_id")
    user = storage.get(User, data['user_id'])
    if not user:
        abort(404)
    if 'name' not in data:
        abort(400, description="Missing name")
    data['city_id'] = city_id
    new_place = Place(**data)
    storage.new(new_place)
    storage.save()
    return make_response(jsonify(new_place.to_dict()), 201)


@app_views.route('/places/<place_id>', methods=['PUT'], strict_slashes=False)
def update_place(place_id):
    """Updates a Place object"""
    place = storage.get(Place, place_id)
    if not place:
        abort(404)
    if not request.is_json:
        abort(400, description="Not a JSON")
    data = request.get_json()
    for key, value in data.items():
        if key not in ['id', 'user_id', 'city_id', 'created_at', 'updated_at']:
            setattr(place, key, value)
    storage.save()
    return make_response(jsonify(place.to_dict()), 200)


@app_views.route('/places_search', methods=['POST'], strict_slashes=False)
def places_search():
    """Search for Place objects based on criteria"""
    if not request.is_json:
        abort(400, description="Not a JSON")

    search_criteria = request.get_json()

    # Extract search criteria
    states = search_criteria.get('states', [])
    cities = search_criteria.get('cities', [])
    amenities = search_criteria.get('amenities', [])

    # Validate search criteria types
    if not isinstance(states, list) or not isinstance(
            cities, list) or not isinstance(amenities, list):
        abort(400, description="Not a JSON")

    # Get all Place objects
    all_places = storage.all(Place).values()

    if not states and not cities and not amenities:
        # Return all places if no criteria are provided
        return jsonify([place.to_dict() for place in all_places])

    filtered_places = set()

    if states:
        # Find all cities in the specified states
        state_ids = set(states)
        city_ids = set()
        for state_id in state_ids:
            state = storage.get(State, state_id)
            if state:
                city_ids.update(city.id for city in state.cities)
        # Find all places in the specified cities
        filtered_places.update(
            place for place in all_places if place.city_id in city_ids)

    if cities:
        # Find all places in the specified cities
        city_ids = set(cities)
        filtered_places.update(
            place for place in all_places if place.city_id in city_ids)

    if amenities:
        # Filter places that have all specified amenities
        amenity_ids = set(amenities)
        filtered_places = {place for place in filtered_places if all(
            amenity.id in place.amenity_ids for amenity
            in storage.all(Amenity).values() if amenity.id in amenity_ids)}

    return jsonify([place.to_dict() for place in filtered_places])
