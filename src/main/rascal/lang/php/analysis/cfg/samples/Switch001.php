<?php
function _wp_mysql_week( $column ) {
        switch ( $start_of_week = (int) get_option( 'start_of_week' ) ) {
        default :
        case 0 :
                return "WEEK( $column, 0 )";
        case 1 :
                return "WEEK( $column, 1 )";
        case 2 :
        case 3 :
        case 4 :
        case 5 :
        case 6 :
                return "WEEK( DATE_SUB( $column, INTERVAL $start_of_week DAY ), 0 )";
        }
}
?>

