import React from 'react';
import { Provider } from 'react-redux';
import { Router } from 'react-router';
import invariant from 'invariant';
import routes from '../routes';

export default class Root extends React.Component {
  render() {
    invariant(
      this.props.routerHistory,
      '<Root /> needs either a routingContext or routerHistory to render.'
    );

    return (
      <Provider store={this.props.store}>
        <Router history={this.props.routerHistory}>
          {routes(this.props.store)}
        </Router>
      </Provider>
    );
  }
}
