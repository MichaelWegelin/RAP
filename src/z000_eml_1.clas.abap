CLASS z000_eml_1 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS z000_eml_1 IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA lv_travel_id TYPE z000_i_travel_1-TravelID.
    DATA lt_travel_create TYPE TABLE FOR CREATE z000_i_travel_1.
    DATA ls_mapped TYPE RESPONSE FOR MAPPED z000_i_travel_1.
    DATA ls_failed TYPE RESPONSE FOR FAILED z000_i_travel_1.
    DATA ls_reported TYPE RESPONSE FOR REPORTED z000_i_travel_1.

    DATA ls_failed_late type response for FAILED LATE z000_i_travel_1.
    DATA ls_reported_late TYPE RESPONSE FOR REPORTED LATE z000_i_travel_1.

* Create Entity Travel of Business Object z000_i_travel_1
    " Fill import parameter
    lt_travel_create = VALUE #( (
            %cid = 'Travel1'
            %data = VALUE #(
                AgencyID = '70025'
                CustomerID = 1
                BeginDate = '20250801'
                EndDate = '20250831'
                OverallStatus = 'O'
                TotalPrice = 999
                CurrencyCode = 'EUR'
            )
        ) ).
    " Create entity
    MODIFY ENTITIES OF z000_i_travel_1
        ENTITY Travel
        CREATE
        FIELDS (
            AgencyID
            CustomerID
            BeginDate
            EndDate
            OverallStatus
            TotalPrice
            CurrencyCode
        )
        WITH lt_travel_create
        MAPPED ls_mapped
        FAILED ls_failed
        REPORTED ls_reported.

    COMMIT ENTITIES RESPONSE
        OF z000_i_travel_1
        FAILED ls_failed_late
        REPORTED ls_reported_late.

    IF sy-subrc eq 0.
        " Get key of created entity
        lv_travel_id = ls_mapped-travel[ 1 ]-TravelID.
    ENDIF.

    out->write( 'Create Travel' ).
    out->write( lt_travel_create ).
    out->write( 'MAPPED' ).
    out->write( ls_mapped ).
    out->write( 'FAILED' ).
    out->write( ls_failed ).
    out->write( 'REPORTED' ).
    out->write( ls_reported ).
    out->write( 'FAILED LATE' ).
    out->write( ls_failed_late ).
    out->write( 'REPORTED LATE' ).
    out->write( ls_reported_late ).

    lv_travel_id = ls_mapped-travel[ 1 ]-TravelID.


  ENDMETHOD.
ENDCLASS.
