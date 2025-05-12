@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel - Overview Page'
@Metadata.ignorePropagatedAnnotations: true

@UI.headerInfo: {
  typeNamePlural: 'Travels',
  typeName: 'Travel',
  imageUrl: 'SAPIconUrl',
  title: {
    label: 'Travel ID',
    value: 'TravelId'
  },
  description: {
    label: 'Customer',
    value: 'CustomerLastName'
  }
}

define view entity Z000_C_OVP
  as select from Z000_I_TRAVEL_1
{
      @UI.facet: [{
          type: #FIELDGROUP_REFERENCE,
          targetQualifier: 'DETAILED',
          isSummary: true
      }]

      @UI.lineItem: [{ position: 10 }]
  key TravelId,
      @UI.selectionField: [{ position: 10 }]
      @ObjectModel.foreignKey.association: '_Agency'
      AgencyId,
      @UI.selectionField: [{ position: 20 }]
      @ObjectModel.foreignKey.association: '_Customer'
      CustomerId,
      @UI.fieldGroup:[{position: 10, qualifier: 'DETAILED', label: 'Customer Name'}]
      @UI.lineItem: [{ position: 20 }]
      _Customer.LastName as CustomerLastName,
      @UI.fieldGroup:[{position: 20, qualifier: 'DETAILED', label: 'Begin Date'}]
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      @UI.fieldGroup:[{position: 30, qualifier: 'DETAILED', label: 'Total Price'}]
      @UI.lineItem: [{ position: 30 }]
      TotalPrice,
      CurrencyCode,
      @UI.fieldGroup:[{position: 40, qualifier: 'DETAILED', label: 'Description'}]
      Description,
      OverallStatus,
      OverallStatusCriticality,
      /* Associations */
      _Agency,
      _Booking,
      _Customer,
      _OverallStatus,
      'sap-icon://travel-itinerary' as SAPIconUrl
}
