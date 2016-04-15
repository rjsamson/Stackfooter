import React from 'react';

export default class ReactWebsocket extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ws: new WebSocket(this.props.url) };
  }

  log(logline) {
    if (this.props.debug === true) {
      console.log(logline);
    }
  }

  componentWillMount() {
    var self = this;
    var ws = self.state.ws;
    ws.onopen = function(event) {
      self.log("Ticker WS open");
    };

    ws.onerror = function(event) {
      self.log("Error");
    };

    ws.onmessage = function(event) {
      var data = JSON.parse(event.data);
      self.log('Websocket incoming data');
      self.log(event.data);
      self.props.onMessage(data);
    }

    ws.onclose = function(event) {
      self.log('Websocket closed');
    }
  }

  componentWillUnmount() {
    this.log('Websocket component unmounting');
    this.state.ws.close();
  }

  render() {
    return (
      <div {...this.props}></div>
    )
  }
}

ReactWebsocket.propTypes = {
    url: React.PropTypes.string.isRequired,
    onMessage: React.PropTypes.func.isRequired,
    debug: React.PropTypes.bool
};

ReactWebsocket.defaultProps = { debug: false };
