import { combineReducers } from 'redux';
import { routerReducer }   from 'react-router-redux';
import session from './session';
import venues from './venues';

export default combineReducers({
  routing: routerReducer,
  session: session,
  venues: venues
});
