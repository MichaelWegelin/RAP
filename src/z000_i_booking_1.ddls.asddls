@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking View - CDS Data Model'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z000_I_BOOKING_1
  as select from z000_booking
  association to parent Z000_I_TRAVEL_1 as _Travel on $projection.TravelID = _Travel.TravelID

  association [1..1] to /DMO/I_Customer          as _Customer      on  $projection.CustomerID = _Customer.CustomerID
  association [1..1] to /DMO/I_Carrier           as _Carrier       on  $projection.AirlineID = _Carrier.AirlineID
  association [1..1] to /DMO/I_Connection        as _Connection    on  $projection.AirlineID    = _Connection.AirlineID
                                                                   and $projection.ConnectionID = _Connection.ConnectionID
  association [1..1] to /DMO/I_Booking_Status_VH as _BookingStatus on  $projection.BookingStatus = _BookingStatus.BookingStatus
  
{
  key travel_id       as TravelID,
  key booking_id      as BookingID,
      booking_date    as BookingDate,
      customer_id     as CustomerID,
      carrier_id      as AirlineID,
      connection_id   as ConnectionID,
      flight_date     as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price    as FlightPrice,
      currency_code   as CurrencyCode,
      booking_status  as BookingStatus,

      //local ETag field --> OData ETag
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at as LastChangedAt,

      /* Associations */
      _Travel,
      _Customer,
      _Carrier,
      _Connection,
      _BookingStatus
}
