import 'package:runners_app/models/geo_point.dart';

const zambiaSouth = -18.08;
const zambiaNorth = -8.22;
const zambiaWest = 21.99;
const zambiaEast = 33.71;

bool inZambia(GeoPoint point) {
  return point.lat >= zambiaSouth &&
      point.lat <= zambiaNorth &&
      point.lng >= zambiaWest &&
      point.lng <= zambiaEast;
}
