@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity Z000_C_TRAVEL_1
  provider contract transactional_query
  as projection on Z000_I_TRAVEL_1
{
  key TravelID,
      @ObjectModel.text.element: ['AgencyName']
      AgencyID,
      _Agency.Name       as AgencyName,
      @ObjectModel.text.element: ['CustomerName']
      CustomerID,
      _Customer.LastName as CustomerName,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,
      Description,
      OverallStatus,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      /* Associations */
      _Booking: redirected to composition child Z000_C_BOOKING_1,
      _Agency,
      _Currency,
      _Customer,
      _OverallStatus
}
