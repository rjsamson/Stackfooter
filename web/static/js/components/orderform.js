import React from 'react';
import { connect } from 'react-redux';
import Actions from '../actions/venues';
import { Link } from 'react-router';

class OrderForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      direction: "buy",
      venue: this.props.venue,
      symbol: "",
      price: "",
      qty: "",
      orderType: "market",
      username: this.props.username
    };
  }

  componentWillReceiveProps(props) {
    if (props.venue != undefined) {
      this.setState({venue: props.venue});
    }
  }

  handleInputChange(field, event) {
    var newState = {};
    var newValue = event.target.value;

    if (field === 'price' || field === 'qty') {
      if (!isNaN(parseInt(newValue)) || newValue === '') {
        newState[field] = newValue === '' ? newValue : parseInt(newValue);
        this.setState(newState);
      } else {
        this.setState({error: true})
      }
    } else {
      newState[field] = newValue;
      this.setState(newState);
    }
  }

  handleSubmit(orderInfo) {
    this.props.dispatch(Actions.placeOrder(orderInfo));
  }

  render() {
    var self = this;
    return (
      <div className="row">
        <div className="form-inline">
          <div className="form-group">
            <label className="sr-only">Direction</label>
            <select className="form-control" id="direction" value={this.state.direction} onChange={this.handleInputChange.bind(this, 'direction')}>
              <option>buy</option>
              <option>sell</option>
            </select>
          </div>
          <div className="form-group">
            <label className="sr-only">Venue</label>
            <input type="text" className="form-control" id="venue" placeholder="venue" value={this.props.venue} onChange={this.handleInputChange.bind(this, 'venue')}></input>
          </div>
          <div className="form-group">
            <label className="sr-only">Symbol</label>
            <input type="text" className="form-control" id="symbol" placeholder="symbol" value={this.state.symbol} onChange={this.handleInputChange.bind(this, 'symbol')}></input>
          </div>
          <div className="form-group">
            <label className="sr-only">Price</label>
            <input type="text" className="form-control" id="price" placeholder="px" value={this.state.price} onChange={this.handleInputChange.bind(this, 'price')}></input>
          </div>
          <div className="form-group">
            <label className="sr-only">Quantity</label>
            <input type="text" className="form-control" id="quantity" placeholder="qty" value={this.state.qty} onChange={this.handleInputChange.bind(this, 'qty')}></input>
          </div>
          <div className="form-group">
            <label className="sr-only">Order Type</label>
            <select className="form-control" id="orderType" value={this.state.orderType} onChange={this.handleInputChange.bind(this, 'orderType')}>
              <option>market</option>
              <option>limit</option>
              <option>fill-or-kill</option>
              <option>immediate-or-cancel</option>
            </select>
          </div>
          <div className="form-group">
            <button className="btn btn-primary" id="submit" onClick={this.handleSubmit.bind(this, this.state)} disabled={!(this.state.venue != "" && this.state.symbol != "" && this.state.price != "" && this.state.qty != "")}>Place Order</button>
          </div>
        </div>
      </div>
    );
  }
}

const mapStateToProps = (state) => ({
  venues: state.venues.venues,
  username: state.session.username
});

export default connect(mapStateToProps)(OrderForm);
