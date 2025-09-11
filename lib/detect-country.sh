declare -A COUNTRY_NAMES=(
    [WW]="Worldwide"
    [AL]="Albania"
    [AM]="Armenia"
    [AU]="Australia"
    [AT]="Austria"
    [AZ]="Azerbaijan"
    [BD]="Bangladesh"
    [BY]="Belarus"
    [BE]="Belgium"
    [BR]="Brazil"
    [KH]="Cambodia"
    [CA]="Canada"
    [CL]="Chile"
    [CN]="China"
    [CO]="Colombia"
    [HR]="Croatia"
    [CZ]="Czechia"
    [DK]="Denmark"
    [EC]="Ecuador"
    [EE]="Estonia"
    [FI]="Finland"
    [FR]="France"
    [GE]="Georgia"
    [DE]="Germany"
    [GR]="Greece"
    [HK]="Hong Kong"
    [HU]="Hungary"
    [IS]="Iceland"
    [IN]="India"
    [ID]="Indonesia"
    [IR]="Iran"
    [IL]="Israel"
    [IT]="Italy"
    [JP]="Japan"
    [KZ]="Kazakhstan"
    [KE]="Kenya"
    [LV]="Latvia"
    [LT]="Lithuania"
    [LU]="Luxembourg"
    [MU]="Mauritius"
    [MX]="Mexico"
    [MD]="Moldova"
    [MA]="Morocco"
    [NP]="Nepal"
    [NL]="Netherlands"
    [NC]="New Caledonia"
    [NZ]="New Zealand"
    [MK]="North Macedonia"
    [NO]="Norway"
    [PY]="Paraguay"
    [PL]="Poland"
    [PT]="Portugal"
    [RO]="Romania"
    [RU]="Russia"
    [RE]="Réunion"
    [SA]="Saudi Arabia"
    [RS]="Serbia"
    [SG]="Singapore"
    [SK]="Slovakia"
    [SI]="Slovenia"
    [ZA]="South Africa"
    [KR]="South Korea"
    [ES]="Spain"
    [SE]="Sweden"
    [CH]="Switzerland"
    [TW]="Taiwan"
    [TH]="Thailand"
    [TR]="Türkiye"
    [UA]="Ukraine"
    [AE]="United Arab Emirates"
    [GB]="United Kingdom"
    [US]="United States"
    [UZ]="Uzbekistan"
    [VN]="Vietnam"
)

detect_country() {
    local cc input

    # Attempt to get the 2-letter country code from public API and make it uppercase
    cc=$(curl -s --max-time 5 https://ipapi.co/country/ | tr -d '\n' | tr '[:lower:]' '[:upper:]')

    # Check 2-letter country code is uppercase and exists in the COUNTRY_NAMES array else use DEFAULT_COUNTRY_CODE
    if [[ "$cc" =~ ^[A-Z]{2}$ && -n "${COUNTRY_NAMES[$cc]}" ]]; then
        COUNTRY_CODE="$cc"
    else
        log WARNING "Could not detect valid country code via API. Falling back to default: $DEFAULT_COUNTRY_CODE."
        COUNTRY_CODE="$DEFAULT_COUNTRY_CODE"
    fi

    # As a last resort, if both the API and default codes are invalid or empty
    if [[ -z "$COUNTRY_CODE" || -z "${COUNTRY_NAMES[$COUNTRY_CODE]}" ]]; then
        echo "Please enter your 2-letter country code:"
        read -r input
        # Convert the input to uppercase
        input=${input^^}

        # Check if the user input is a valid 2-letter country code, else Worldwide
        if [[ "$input" =~ ^[A-Z]{2}$ && -n "${COUNTRY_NAMES[$input]}" ]]; then
            COUNTRY_CODE="$input"
        else
            log ERROR "Invalid input or no valid default country. Defaulting to Worldwide"
            COUNTRY_CODE="WW"
        fi
    fi

    # Look up the full country name using the final country code
    COUNTRY_NAME="${COUNTRY_NAMES[$COUNTRY_CODE]}"
    export COUNTRY_CODE COUNTRY_NAME
    log INFO "Using country: $COUNTRY_NAME ($COUNTRY_CODE)"
}
