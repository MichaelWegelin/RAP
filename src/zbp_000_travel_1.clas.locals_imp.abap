CLASS lhc_Z000_I_TRAVEL_1 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR z000_i_travel_1 RESULT result.

ENDCLASS.

CLASS lhc_Z000_I_TRAVEL_1 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

ENDCLASS.
