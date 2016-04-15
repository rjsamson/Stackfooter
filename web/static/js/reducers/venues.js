import Actions from '../actions/venues';

const initialState = {
  venues: [],
  fetching: false
};

export default function reducer(state = initialState, action) {
  switch (action.type) {
    case 'VENUES_RECEIVED':
      return { ...state, fetching: false, venues: action.venues };
    case 'VENUES_FETCHING':
      return { ...state, fetching: true};
    case 'VENUE_STOCKS_FETCHING':
      return { ...state, fetching: true};
    case 'VENUE_STOCKS_RECEIVED':
      var venue = state.venues.find(function(ven) {
        return ven.venue === action.venue;
      });

      var venues = state.venues.filter(function(ven) {
        return ven.venue != action.venue;
      });

      venues = venues.concat(venue);
      venue.stocks = action.stocks;

      return { ...state, fetching: false, venues: venues};
    default:
      return state;
  }
}
