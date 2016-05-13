const initialState = {
  orders: {},
  fetching: false
};

export default function reducer(state = initialState, action) {
  switch (action.type) {
    case 'PLACING_ORDER':
      return { ...state, fetching: true };
    case 'ORDER_PLACED':
      var orders = state.orders;
      var venue = action.venue;

      if (state.orders[venue] === undefined) {
        state.orders[venue] = [];
      }

      state.orders[venue].unshift(action.order);

      return { fetching: false, orders: orders };
    default:
      return state;
  }
}
