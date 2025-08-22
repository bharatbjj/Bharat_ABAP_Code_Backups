FORM process_main.

  DATA : l_tab_data  TYPE STANDARD TABLE OF g_typ_data,
		     l_wa_data   LIKE LINE OF 		    l_tab_data,
         l_var_total TYPE i,
         l_var_count TYPE i,
		     l_var_limit TYPE i VALUE '500'.	" Interval for timer reset
  
**Get the Total number of records  
  DESCRIBE TABLE l_tab_data LINES l_var_total.
  
  LOOP AT l_tab_data into l_wa_data.
**Increment the counter  
	l_var_count = l_var_count + 1.	
*{
*Do somthing
*}

**Reset the timer at the inerval
	PERFORM check_and_reset_timer USING l_var_total
										l_var_count							
										l_var_limit.
  ENDLOOP.

ENDFORM.

FORM check_and_reset_timer  USING  i_var_total TYPE i
                                   i_var_count TYPE i
                                   i_var_limit TYPE i.
  DATA : l_var_mod 	TYPE i,
         l_var_perc TYPE i,
         l_var_msg 	TYPE bapi_msg.

  l_var_mod = i_var_count MOD i_var_limit.

  IF l_var_mod = 0.
    l_var_perc = ( i_var_count * 100 ) / i_var_total.

** &1 of &2 Records Processed....
    MESSAGE i002 WITH i_var_count i_var_total INTO l_var_msg.
    CONDENSE l_var_msg.

    PERFORM progress_indicator USING l_var_perc l_var_msg.
  ENDIF.

ENDFORM. 


FORM progress_indicator  USING  i_var_percent
                                i_var_text.

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      percentage = i_var_percent
      text       = i_var_text
    EXCEPTIONS
      OTHERS     = 1.

ENDFORM.