@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity Z000_C_BOOKING_1
  as projection on Z000_I_BOOKING_1
{
  key TravelID,
  key BookingID,
      BookingDate,
      @ObjectModel.text.element: ['CustomerName']
      CustomerID,
      _Customer.LastName as CustomerName,
      @ObjectModel.text.element: ['AirlineName']
      AirlineID,
      _Carrier.Name      as AirlineName,
      ConnectionId,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      LastChangedAt,
      
      /* Associations */
      _Travel: redirected to parent Z000_C_TRAVEL_1,
      _BookingStatus,
      _Carrier,
      _Connection,
      _Customer
}
