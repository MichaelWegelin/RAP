@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@Search.searchable: true

define root view entity Z000_C_TRAVEL_1
  provider contract transactional_query
  as projection on Z000_I_TRAVEL_1
{
  key TravelId,
      @ObjectModel.text.element: ['AgencyName']
      AgencyId,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      _Agency.Name       as AgencyName,
      @ObjectModel.text.element: ['CustomerName']
      CustomerId,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      _Customer.LastName as CustomerName,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,
      Description,
      @ObjectModel.text.element: ['OverallStatusText']    
      OverallStatus,
      _OverallStatus._Text.Text as OverallStatusText : localized,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      /* Associations */
      _Booking : redirected to composition child Z000_C_BOOKING_1,
      _Agency,
      _Currency,
      _Customer,
      _OverallStatus
}
