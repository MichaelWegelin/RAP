CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.


    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateTotalPrice.

    METHODS validateConnection FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateConnection.

    METHODS validateCurrencyCode FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateCurrencyCode.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateCustomer.

    METHODS validateFlightPrice FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateFlightPrice.

    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateStatus.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD calculateTotalPrice.
    DATA: travel_ids TYPE STANDARD TABLE OF z000_i_travel_1 WITH UNIQUE HASHED KEY key COMPONENTS TravelId.

    travel_ids = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING TravelId = TravelId ).

    MODIFY ENTITIES OF z000_i_travel_1 IN LOCAL MODE
      ENTITY Travel
        EXECUTE ReCalcTotalPrice
        FROM CORRESPONDING #( travel_ids ).

  ENDMETHOD.

  METHOD validateConnection.
    READ ENTITIES OF z000_i_travel_1 IN LOCAL MODE
      ENTITY Booking
        FIELDS ( BookingId AirlineId ConnectionId FlightDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    READ ENTITIES OF z000_i_travel_1 IN LOCAL MODE
      ENTITY Booking BY \_Travel
        FROM CORRESPONDING #( bookings )
      LINK DATA(travel_booking_links).

    LOOP AT bookings ASSIGNING FIELD-SYMBOL(<booking>).
      " Raise message for non existing airline ID
      IF <booking>-AirlineId IS INITIAL.

        APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                = <booking>-%tky
                        %msg                = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_airline_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path               = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = <booking>-%tky ]-target-%tky )
                        %element-AirlineId = if_abap_behv=>mk-on
                       ) TO reported-booking.
      ENDIF.
      " Raise message for non existing connection ID
      IF <booking>-ConnectionId IS INITIAL.

        APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                   = <booking>-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_connection_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                  = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = <booking>-%tky ]-target-%tky )
                        %element-ConnectionId = if_abap_behv=>mk-on
                       ) TO reported-booking.
      ENDIF.
      " Raise message for non existing flight date
      IF <booking>-FlightDate IS INITIAL.

        APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                 = <booking>-%tky
                        %msg                 = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_flight_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = <booking>-%tky ]-target-%tky )
                        %element-FlightDate = if_abap_behv=>mk-on
                       ) TO reported-booking.
      ENDIF.
      " check if flight connection exists
      IF <booking>-AirlineId IS NOT INITIAL AND
         <booking>-ConnectionId IS NOT INITIAL AND
         <booking>-FlightDate IS NOT INITIAL.

        SELECT SINGLE Carrier_ID, Connection_ID, Flight_Date   FROM /dmo/flight  WHERE  carrier_id    = @<booking>-AirlineId
                                                               AND  connection_id = @<booking>-ConnectionId
                                                               AND  flight_date   = @<booking>-FlightDate
                                                               INTO  @DATA(flight).

        IF sy-subrc <> 0.

          APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
          APPEND VALUE #( %tky                   = <booking>-%tky
                          %msg                   = NEW /dmo/cm_flight_messages(
                                                                textid        = /dmo/cm_flight_messages=>no_flight_exists
                                                                carrier_id    = <booking>-AirlineId
                                                                connection_id = <booking>-ConnectionId
                                                                flight_date   = <booking>-FlightDate
                                                                severity      = if_abap_behv_message=>severity-error )
                          %path                  = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = <booking>-%tky ]-target-%tky )
                          %element-FlightDate   = if_abap_behv=>mk-on
                          %element-AirlineId    = if_abap_behv=>mk-on
                          %element-ConnectionId = if_abap_behv=>mk-on
                        ) TO reported-booking.

        ENDIF.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCurrencyCode.
    READ ENTITIES OF z000_i_travel_1 IN LOCAL MODE
      ENTITY booking
        FIELDS ( CurrencyCode )
        WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    DATA: currencies TYPE SORTED TABLE OF I_Currency WITH UNIQUE KEY currency.

    currencies = CORRESPONDING #( bookings DISCARDING DUPLICATES MAPPING currency = CurrencyCode EXCEPT * ).
    DELETE currencies WHERE currency IS INITIAL.

    IF currencies IS NOT INITIAL.
      SELECT FROM I_Currency FIELDS currency
        FOR ALL ENTRIES IN @currencies
        WHERE currency = @currencies-currency
        INTO TABLE @DATA(currency_db).
    ENDIF.


    LOOP AT bookings INTO DATA(booking).
      IF booking-CurrencyCode IS INITIAL.
        " Raise message for empty Currency
        APPEND VALUE #( %tky                   = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                   = booking-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                        textid    = /dmo/cm_flight_messages=>currency_required
                                                        severity  = if_abap_behv_message=>severity-error )
                        %element-CurrencyCode = if_abap_behv=>mk-on
                        %path                  = VALUE #(  travel-TravelId    = booking-TravelId )
                      ) TO reported-booking.
      ELSEIF NOT line_exists( currency_db[ currency = booking-CurrencyCode ] ).
        " Raise message for not existing Currency
        APPEND VALUE #( %tky                   = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                   = booking-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                        textid    = /dmo/cm_flight_messages=>currency_not_existing
                                                        severity  = if_abap_behv_message=>severity-error
                                                        currency_code = booking-CurrencyCode )
                        %path                  = VALUE #(  travel-TravelId    = booking-TravelId )
                        %element-CurrencyCode = if_abap_behv=>mk-on
                      ) TO reported-booking.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.
    READ ENTITIES OF z000_i_travel_1 IN LOCAL MODE
    ENTITY Booking
      FIELDS ( CustomerId )
      WITH CORRESPONDING #( keys )
  RESULT DATA(bookings).

    READ ENTITIES OF z000_i_travel_1 IN LOCAL MODE
      ENTITY Booking BY \_Travel
        FROM CORRESPONDING #( bookings )
      LINK DATA(travel_booking_links).

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    customers = CORRESPONDING #( bookings DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.

    IF  customers IS NOT INITIAL.
      " Check if customer ID exists
      SELECT FROM /dmo/customer FIELDS customer_id
                                FOR ALL ENTRIES IN @customers
                                WHERE customer_id = @customers-customer_id
      INTO TABLE @DATA(valid_customers).
    ENDIF.

    " Raise message for non existing and initial customer id
    LOOP AT bookings INTO DATA(booking).
      IF booking-CustomerId IS  INITIAL.

        APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                 = booking-%tky
                        %msg                 = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_customer_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = booking-%tky ]-target-%tky )
                        %element-CustomerId = if_abap_behv=>mk-on
                       ) TO reported-booking.

      ELSEIF booking-CustomerId IS NOT INITIAL AND NOT line_exists( valid_customers[ customer_id = booking-CustomerId ] ).

        APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                 = booking-%tky
                        %msg                 = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>customer_unkown
                                                                customer_id = booking-CustomerId
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = booking-%tky ]-target-%tky )
                        %element-CustomerId = if_abap_behv=>mk-on
                       ) TO reported-booking.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateFlightPrice.
    READ ENTITIES OF z000_i_travel_1 IN LOCAL MODE
      ENTITY booking
        FIELDS ( FlightPrice )
        WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    READ ENTITIES OF z000_i_travel_1 IN LOCAL MODE
      ENTITY Booking BY \_Travel
        FROM CORRESPONDING #( bookings )
      LINK DATA(travel_booking_links).

    LOOP AT bookings INTO DATA(booking) WHERE FlightPrice < 0.
      " Raise message for flight price < 0
      APPEND VALUE #( %tky                  = booking-%tky ) TO failed-booking.
      APPEND VALUE #( %tky                  = booking-%tky
                      %msg                  = NEW /dmo/cm_flight_messages(
                                                     textid      = /dmo/cm_flight_messages=>flight_price_invalid
                                                     severity    = if_abap_behv_message=>severity-error )
                      %element-FlightPrice = if_abap_behv=>mk-on
                      %path                 = VALUE #( travel-%tky = travel_booking_links[ KEY id source-%tky = booking-%tky ]-target-%tky )
                    ) TO reported-booking.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateStatus.
  ENDMETHOD.

ENDCLASS.
