import { combineReducers } from 'redux';
import { routerReducer }   from 'react-router-redux';
import session from './session';
import venues from './venues';
import orders from './orders';

export default combineReducers({
  routing: routerReducer,
  session: session,
  venues: venues,
  orders: orders
});
