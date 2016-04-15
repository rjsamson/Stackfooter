import { httpGet } from '../utils';

const Actions = {
  fetchVenues: () => {
    var that = this;
    return dispatch => {
      dispatch({type: 'VENUES_FETCHING'});

      httpGet('/ob/api/venues')
      .then((data) => {
        var venues = data.venues.map(function(venue) {
          return {...venue, stocks: []}
        });

        dispatch({
          type: 'VENUES_RECEIVED',
          venues: venues
        });

        venues.forEach(function(venue) {
          dispatch(Actions.fetchStocksOnVenue(venue.venue));
        })
      });
    };
  },

  fetchStocksOnVenue: (venue) => {
    return dispatch => {
      dispatch({type: 'VENUE_STOCKS_FETCHING'});

      httpGet(`/ob/api/venues/${venue}/stocks`)
      .then((data) => {
        dispatch({
          type: 'VENUE_STOCKS_RECEIVED',
          stocks: data.symbols,
          venue: venue
        });
      });
    };
  }
}

export default Actions;
