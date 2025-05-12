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
      @Consumption.valueHelpDefinition: [{
        entity : {
            name: '/DMO/I_Agency_StdVH',
            element: 'AgencyID'  },
        useForValidation: true
      }]
      AgencyId,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      _Agency.Name              as AgencyName,
      _Agency.City              as AgencyCity,
      @Semantics.eMail.address: true
      _Agency.EMailAddress      as AgencyEmailAddress,
      @ObjectModel.text.element: ['CustomerName']
      @Consumption.valueHelpDefinition: [{
        entity: {
            name: '/DMO/I_Customer_StdVH',
            element: 'CustomerID' },
        useForValidation: true
      }]
      CustomerId,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      _Customer.LastName        as CustomerName,
      _Customer.FirstName       as CustomerFirstName,
      _Customer.City            as CustomerCity,
      @Semantics.telephone.type: [ #PREF ]
      _Customer.PhoneNumber     as CustomerPhoneNumber,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      @Consumption.valueHelpDefinition: [{
        entity: {
            name: 'I_CurrencyStdVH', 
            element: 'Currency' }, 
        useForValidation: true 
      }]
      CurrencyCode,
      Description,
      @ObjectModel.text.element: ['OverallStatusText']
      @Consumption.valueHelpDefinition: [
        { entity: { 
            name: '/DMO/I_Overall_Status_VH', 
            element: 'OverallStatus' }
      }]
      OverallStatus,
      _OverallStatus._Text.Text as OverallStatusText : localized,
      OverallStatusCriticality,
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
