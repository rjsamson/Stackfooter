import { Redirect, Route } from 'react-router';
import React from 'react';
import MainLayout from '../layouts/main';
import MainMenu from '../views/menu/main';
import Venues from '../views/venues/venues';
import Venue from '../views/venues/venue';

export default function routes(store) {
    return (
      <Route component={MainLayout} store={store}>
        <Route path="/trade" component={Venues} store={store} />
        <Redirect from="/trade" to="/trade/venues" />
        <Route path="/trade/venues" component={Venues} store={store} >
          <Route path="/trade/venues/:venue" component={Venue} />
        </Route>
      </Route>
   );
}
