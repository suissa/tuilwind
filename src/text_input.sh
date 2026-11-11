#!/bin/sh
# SPDX-License-Identifier: ISC
# src/text_input.sh - single-line TextInput Actor. Source after actor.sh and str.sh.
if test -n "${_tuish_text_input_loaded:-}"; then return 0; fi
_tuish_text_input_loaded=1


# Grapheme boundaries: base codepoint plus combining marks, variation selectors,
# emoji modifiers, ZWJ-linked codepoints and paired regional indicators.
_tuish_input_cp_at () {
  local _s=$1 _i=$2 _b0 _b1 _b2 _b3
  _tuish_ord "${_s:$_i:1}"; _b0=$_tuish_code
  if test "$_b0" -lt 128; then _tuish_input_cp=$_b0; _tuish_input_bytes=1
  elif test "$_b0" -lt 224; then
    _tuish_ord "${_s:$((_i + 1)):1}"; _b1=$_tuish_code
    _tuish_input_cp=$(( ((_b0 & 31) << 6) | (_b1 & 63) )); _tuish_input_bytes=2
  elif test "$_b0" -lt 240; then
    _tuish_ord "${_s:$((_i + 1)):1}"; _b1=$_tuish_code
    _tuish_ord "${_s:$((_i + 2)):1}"; _b2=$_tuish_code
    _tuish_input_cp=$(( ((_b0 & 15) << 12) | ((_b1 & 63) << 6) | (_b2 & 63) )); _tuish_input_bytes=3
  else
    _tuish_ord "${_s:$((_i + 1)):1}"; _b1=$_tuish_code
    _tuish_ord "${_s:$((_i + 2)):1}"; _b2=$_tuish_code
    _tuish_ord "${_s:$((_i + 3)):1}"; _b3=$_tuish_code
    _tuish_input_cp=$(( ((_b0 & 7) << 18) | ((_b1 & 63) << 12) | ((_b2 & 63) << 6) | (_b3 & 63) )); _tuish_input_bytes=4
  fi
}
_tuish_input_is_extend () {
  case "$1" in
    768|769|770|771|772|773|774|775|776|777|778|779|780|781|782|783|784|785|786|787|788|789|790|791|792|793|794|795|796|797|798|799|800|801|802|803|804|805|806|807|808|809|810|811|812|813|814|815|816|817|818|819|820|821|822|823|824|825|826|827|828|829|830|831|832|833|834|835|836|837|838|839|840|841|842|843|844|845|846|847|848|849|850|851|852|853|854|855|856|857|858|859|860|861|862|863|864|865|866|867|868|869|870|871|872|873|874|875|876|877|878|879|1155|1156|1157|1158|1159|1160|1161|1162|1163|1164|1165|1166|1167|1168|1169|1170|1171|1172|1173|1174|1175|1176|1177|1178|1179|1180|1181|1182|1183|6832|6833|6834|6835|6836|6837|6838|6839|6840|6841|6842|6843|6844|6845|6846|6847|6848|6849|6850|6851|6852|6853|6854|6855|6856|6857|6858|6859|6860|6861|6862|6863|6864|6865|6866|6867|6868|6869|6870|6871|6872|6873|6874|6875|6876|6877|6878|6879|6880|6881|6882|6883|6884|6885|6886|6887|6888|6889|6890|6891|6892|6893|6894|6895|6896|6897|6898|6899|6900|6901|6902|6903|6904|6905|6906|6907|6908|6909|6910|6911|6912|6913|6914|6915|6916|6917|6918|6919|6920|6921|6922|6923|6924|6925|6926|6927|6928|6929|6930|6931|6932|6933|6934|6935|6936|6937|6938|6939|6940|6941|6942|6943|6944|6945|6946|6947|6948|6949|6950|6951|6952|6953|6954|6955|6956|6957|6958|6959|6960|6961|6962|6963|6964|6965|6966|6967|6968|6969|6970|6971|6972|6973|6974|6975|6976|6977|6978|6979|6980|6981|6982|6983|6984|6985|6986|6987|6988|6989|6990|6991|6992|6993|6994|6995|6996|6997|6998|6999|7000|7001|7002|7003|7004|7005|7006|7007|7008|7009|7010|7011|7012|7013|7014|7015|7016|7017|7018|7019|7020|7021|7022|7023|7024|7025|7026|7027|7028|7029|7030|7031|7032|7033|7034|7035|7036|7037|7038|7039|7040|7041|7042|7043|7044|7045|7046|7047|7048|7049|7050|7051|7052|7053|7054|7055|7056|7057|7058|7059|7060|7061|7062|7063|7064|7065|7066|7067|7068|7069|7070|7071|7072|7073|7074|7075|7076|7077|7078|7079|7080|7081|7082|7083|7084|7085|7086|7087|7088|7089|7090|7091|7092|7093|7094|7095|7096|7097|7098|7099|7100|7101|7102|7103|7104|7105|7106|7107|7108|7109|7110|7111|7112|7113|7114|7115|7116|7117|7118|7119|7120|7121|7122|7123|7124|7125|7126|7127|7128|7129|7130|7131|7132|7133|7134|7135|7136|7137|7138|7139|7140|7141|7142|7143|7144|7145|7146|7147|7148|7149|7150|7151|7152|7153|7154|7155|7156|7157|7158|7159|7160|7161|7162|7163|7164|7165|7166|7167|7168|7169|7170|7171|7172|7173|7174|7175|7176|7177|7178|7179|7180|7181|7182|7183|7184|7185|7186|7187|7188|7189|7190|7191|7192|7193|7194|7195|7196|7197|7198|7199|7200|7201|7202|7203|7204|7205|7206|7207|7208|7209|7210|7211|7212|7213|7214|7215|7216|7217|7218|7219|7220|7221|7222|7223|7224|7225|7226|7227|7228|7229|7230|7231|7232|7233|7234|7235|7236|7237|7238|7239|7240|7241|7242|7243|7244|7245|7246|7247|7248|7249|7250|7251|7252|7253|7254|7255|7256|7257|7258|7259|7260|7261|7262|7263|7264|7265|7266|7267|7268|7269|7270|7271|7272|7273|7274|7275|7276|7277|7278|7279|7280|7281|7282|7283|7284|7285|7286|7287|7288|7289|7290|7291|7292|7293|7294|7295|7296|7297|7298|7299|7300|7301|7302|7303|7304|7305|7306|7307|7308|7309|7310|7311|7312|7313|7314|7315|7316|7317|7318|7319|7320|7321|7322|7323|7324|7325|7326|7327|7328|7329|7330|7331|7332|7333|7334|7335|7336|7337|7338|7339|7340|7341|7342|7343|7344|7345|7346|7347|7348|7349|7350|7351|7352|7353|7354|7355|7356|7357|7358|7359|7360|7361|7362|7363|7364|7365|7366|7367|7368|7369|7370|7371|7372|7373|7374|7375|7376|7377|7378|7379|7380|7381|7382|7383|7384|7385|7386|7387|7388|7389|7390|7391|7392|7393|7394|7395|7396|7397|7398|7399|7400|7401|7402|7403|7404|7405|7406|7407|7408|7409|7410|7411|7412|7413|7414|7415|7416|7417|7418|7419|7420|7421|7422|7423|7424|7425|7426|7427|7428|7429|7430|7431|7432|7433|7434|7435|7436|7437|7438|7439|7440|7441|7442|7443|7444|7445|7446|7447|7448|7449|7450|7451|7452|7453|7454|7455|7456|7457|7458|7459|7460|7461|7462|7463|7464|7465|7466|7467|7468|7469|7470|7471|7472|7473|7474|7475|7476|7477|7478|7479|7480|7481|7482|7483|7484|7485|7486|7487|7488|7489|7490|7491|7492|7493|7494|7495|7496|7497|7498|7499|7500|7501|7502|7503|7504|7505|7506|7507|7508|7509|7510|7511|7512|7513|7514|7515|7516|7517|7518|7519|7520|7521|7522|7523|7524|7525|7526|7527|7528|7529|7530|7531|7532|7533|7534|7535|7536|7537|7538|7539|7540|7541|7542|7543|7544|7545|7546|7547|7548|7549|7550|7551|7552|7553|7554|7555|7556|7557|7558|7559|7560|7561|7562|7563|7564|7565|7566|7567|7568|7569|7570|7571|7572|7573|7574|7575|7576|7577|7578|7579|7580|7581|7582|7583|7584|7585|7586|7587|7588|7589|7590|7591|7592|7593|7594|7595|7596|7597|7598|7599|7600|7601|7602|7603|7604|7605|7606|7607|7608|7609|7610|7611|7612|7613|7614|7615|7616|7617|7618|7619|7620|7621|7622|7623|7624|7625|7626|7627|7628|7629|7630|7631|7632|7633|7634|7635|7636|7637|7638|7639|7640|7641|7642|7643|7644|7645|7646|7647|7648|7649|7650|7651|7652|7653|7654|7655|7656|7657|7658|7659|7660|7661|7662|7663|7664|7665|7666|7667|7668|7669|7670|7671|7672|7673|7674|7675|7676|7677|7678|7679|7680|7681|7682|7683|7684|7685|7686|7687|7688|7689|7690|7691|7692|7693|7694|7695|7696|7697|7698|7699|7700|7701|7702|7703|7704|7705|7706|7707|7708|7709|7710|7711|7712|7713|7714|7715|7716|7717|7718|7719|7720|7721|7722|7723|7724|7725|7726|7727|7728|7729|7730|7731|7732|7733|7734|7735|7736|7737|7738|7739|7740|7741|7742|7743|7744|7745|7746|7747|7748|7749|7750|7751|7752|7753|7754|7755|7756|7757|7758|7759|7760|7761|7762|7763|7764|7765|7766|7767|7768|7769|7770|7771|7772|7773|7774|7775|7776|7777|7778|7779|7780|7781|7782|7783|7784|7785|7786|7787|7788|7789|7790|7791|7792|7793|7794|7795|7796|7797|7798|7799|7800|7801|7802|7803|7804|7805|7806|7807|7808|7809|7810|7811|7812|7813|7814|7815|7816|7817|7818|7819|7820|7821|7822|7823|7824|7825|7826|7827|7828|7829|7830|7831|7832|7833|7834|7835|7836|7837|7838|7839|7840|7841|7842|7843|7844|7845|7846|7847|7848|7849|7850|7851|7852|7853|7854|7855|7856|7857|7858|7859|7860|7861|7862|7863|7864|7865|7866|7867|7868|7869|7870|7871|7872|7873|7874|7875|7876|7877|7878|7879|7880|7881|7882|7883|7884|7885|7886|7887|7888|7889|7890|7891|7892|7893|7894|7895|7896|7897|7898|7899|7900|7901|7902|7903|7904|7905|7906|7907|7908|7909|7910|7911|7912|7913|7914|7915|7916|7917|7918|7919|7920|7921|7922|7923|7924|7925|7926|7927|7928|7929|7930|7931|7932|7933|7934|7935|7936|7937|7938|7939|7940|7941|7942|7943|7944|7945|7946|7947|7948|7949|7950|7951|7952|7953|7954|7955|7956|7957|7958|7959|7960|7961|7962|7963|7964|7965|7966|7967|7968|7969|7970|7971|7972|7973|7974|7975|7976|7977|7978|7979|7980|7981|7982|7983|7984|7985|7986|7987|7988|7989|7990|7991|7992|7993|7994|7995|7996|7997|7998|7999|8000|8001|8002|8003|8004|8005|8006|8007|8008|8009|8010|8011|8012|8013|8014|8015|8016|8017|8018|8019|8020|8021|8022|8023|8024|8025|8026|8027|8028|8029|8030|8031|8032|8033|8034|8035|8036|8037|8038|8039|8040|8041|8042|8043|8044|8045|8046|8047|8048|8049|8050|8051|8052|8053|8054|8055|8056|8057|8058|8059|8060|8061|8062|8063|8064|8065|8066|8067|8068|8069|8070|8071|8072|8073|8074|8075|8076|8077|8078|8079|8080|8081|8082|8083|8084|8085|8086|8087|8088|8089|8090|8091|8092|8093|8094|8095|8096|8097|8098|8099|8100|8101|8102|8103|8104|8105|8106|8107|8108|8109|8110|8111|8112|8113|8114|8115|8116|8117|8118|8119|8120|8121|8122|8123|8124|8125|8126|8127|8128|8129|8130|8131|8132|8133|8134|8135|8136|8137|8138|8139|8140|8141|8142|8143|8144|8145|8146|8147|8148|8149|8150|8151|8152|8153|8154|8155|8156|8157|8158|8159|8160|8161|8162|8163|8164|8165|8166|8167|8168|8169|8170|8171|8172|8173|8174|8175|8176|8177|8178|8179|8180|8181|8182|8183|8184|8185|8186|8187|8188|8189|8190|8191|65024|65025|65026|65027|65028|65029|65030|65031|65032|65033|65034|65035|65036|65037|65038|65039|65040|65041|65042|65043|65044|65045|65046|65047|65048|65049|65050|65051|65052|65053|65054|65055|65056|65057|65058|65059|65060|65061|65062|65063|65064|65065|65066|65067|65068|65069|65070|65071|65072|65073|65074|65075|65076|65077|65078|65079|65080|65081|65082|65083|65084|65085|65086|65087|65088|65089|65090|65091|65092|65093|65094|65095|65096|65097|65098|65099|65100|65101|65102|65103|65104|65105|65106|65107|65108|65109|65110|65111|65112|65113|65114|65115|65116|65117|65118|65119|65120|65121|65122|65123|65124|65125|65126|65127|65128|65129|65130|65131|65132|65133|65134|65135|65039|917760|917761|917762|917763|917764|917765|917766|917767|917768|917769|917770|917771|917772|917773|917774|917775|917776|917777|917778|917779|917780|917781|917782|917783|917784|917785|917786|917787|917788|917789|917790|917791|917792|917793|917794|917795|917796|917797|917798|917799|917800|917801|917802|917803|917804|917805|917806|917807|917808|917809|917810|917811|917812|917813|917814|917815|917816|917817|917818|917819|917820|917821|917822|917823|917824|917825|917826|917827|917828|917829|917830|917831|917832|917833|917834|917835|917836|917837|917838|917839|917840|917841|917842|917843|917844|917845|917846|917847|917848|917849|917850|917851|917852|917853|917854|917855|917856|917857|917858|917859|917860|917861|917862|917863|917864|917865|917866|917867|917868|917869|917870|917871|917872|917873|917874|917875|917876|917877|917878|917879|917880|917881|917882|917883|917884|917885|917886|917887|917888|917889|917890|917891|917892|917893|917894|917895|917896|917897|917898|917899|917900|917901|917902|917903|917904|917905|917906|917907|917908|917909|917910|917911|917912|917913|917914|917915|917916|917917|917918|917919|917920|917921|917922|917923|917924|917925|917926|917927|917928|917929|917930|917931|917932|917933|917934|917935|917936|917937|917938|917939|917940|917941|917942|917943|917944|917945|917946|917947|917948|917949|917950|917951|917952|917953|917954|917955|917956|917957|917958|917959|917960|917961|917962|917963|917964|917965|917966|917967|917968|917969|917970|917971|917972|917973|917974|917975|917976|917977|917978|917979|917980|917981|917982|917983|917984|917985|917986|917987|917988|917989|917990|917991|917992|917993|917994|917995|917996|917997|917998|917999|126976|127023|127995|127999) return 0;;
    *) return 1;;
  esac
}
_tuish_input_next_boundary () {
  local _s=$1 _i=$2 _n _first
  test "$_i" -lt "${#_s}" || { TUISH_TEXT_INPUT_NEXT=$_i; return 0; }
  _tuish_input_cp_at "$_s" "$_i"; _first=$_tuish_input_cp; _i=$((_i + _tuish_input_bytes))
  if test "$_first" -ge 127462 && test "$_first" -le 127487
  then
    if test "$_i" -lt "${#_s}"; then _tuish_input_cp_at "$_s" "$_i"; if test "$_tuish_input_cp" -ge 127462 && test "$_tuish_input_cp" -le 127487; then _i=$((_i + _tuish_input_bytes)); fi; fi
  fi
  while test "$_i" -lt "${#_s}"
  do
    _tuish_input_cp_at "$_s" "$_i"; _n=$_tuish_input_cp
    if _tuish_input_is_extend "$_n"; then _i=$((_i + _tuish_input_bytes)); continue; fi
    if test "$_n" -eq 8205
    then
      _i=$((_i + _tuish_input_bytes))
      test "$_i" -lt "${#_s}" || break
      _tuish_input_cp_at "$_s" "$_i"; _i=$((_i + _tuish_input_bytes))
      continue
    fi
    break
  done
  TUISH_TEXT_INPUT_NEXT=$_i
}
_tuish_input_graphemes () {
  local _s=$1 _i=0 _n=0
  while test "$_i" -lt "${#_s}"
  do
    _tuish_input_next_boundary "$_s" "$_i"; _i=$TUISH_TEXT_INPUT_NEXT
    _n=$((_n + 1))
  done
  TUISH_TEXT_INPUT_LENGTH=$_n
}
_tuish_input_byte_offset () {
  local _s=$1 _target=$2 _i=0 _n=0
  while test "$_n" -lt "$_target" && test "$_i" -lt "${#_s}"
  do
    _tuish_input_next_boundary "$_s" "$_i"; _i=$TUISH_TEXT_INPUT_NEXT
    _n=$((_n + 1))
  done
  TUISH_TEXT_INPUT_OFFSET=$_i
}

_tuish_input_clean () {
  local _s=$1 _i=0 _ch _out='' _n
  # Preserve UTF-8 bytes; remove C0 controls and DEL to prevent terminal injection.
  while test $_i -lt ${#_s}
  do
    _ch=${_s:$_i:1}
    _tuish_ord "$_ch"; _n=$_tuish_code
    if test "$_n" -ge 32 && test "$_n" -ne 127; then _out="${_out}${_ch}"; fi
    _i=$((_i + 1))
  done
  TUISH_TEXT_INPUT_CLEAN=$_out
}
tuish_text_input_create () {
  local _id=$1 _placeholder=${2:-} _max=${3:-0} _mask=${4:-}
  _tuish_actor_valid_name "$_id" && tuish_actor_supported text-input || return 2
  _tuish_actor_is_uint "$_max" || return 2
  tuish_actor_create "$_id" text-input || return
  tuish_actor_set "$_id" value '' || return
  tuish_actor_set "$_id" cursor_position 0 || return
  tuish_actor_set "$_id" placeholder "$_placeholder" || return
  tuish_actor_set "$_id" max_length "$_max" || return
  tuish_actor_set "$_id" mask_char "$_mask" || return
  tuish_actor_set "$_id" focus_state 0 || return
  tuish_actor_set "$_id" validation valid || return
}
tuish_text_input_set () {
  local _id=$1 _text=${2:-} _max _len
  _tuish_input_clean "$_text"; _text=$TUISH_TEXT_INPUT_CLEAN
  tuish_actor_get "$_id" max_length || return; _max=$TUISH_ACTOR_VALUE
  # Count Unicode codepoints (not bytes); reject rather than silently truncate.
  local _tuish_input_text=$_text
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  test "$_max" -eq 0 || test "$_len" -le "$_max" || return 2
  tuish_actor_set "$_id" value "$_text" || return
  tuish_actor_set "$_id" cursor_position "$_len" || return
  tuish_actor_set "$_id" validation valid
  _tuish_actor_emit "$_id" data_change "$_text"
}
tuish_text_input_insert () {
  local _id=$1 _insert=${2:-} _value _cursor _max _len _left _right _next _insert_len _i
  _tuish_input_clean "$_insert"; _insert=$TUISH_TEXT_INPUT_CLEAN
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" max_length || return; _max=$TUISH_ACTOR_VALUE
  local _tuish_input_text=$_value
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  local _tuish_input_text=$_insert
  _tuish_input_len; _insert_len=$TUISH_TEXT_INPUT_LENGTH
  test "$_max" -eq 0 || test $((_len + _insert_len)) -le "$_max" || return 2
  _tuish_input_byte_offset "$_value" "$_cursor"; _i=$TUISH_TEXT_INPUT_OFFSET
  _left=${_value:0:$_i}; _right=${_value:$_i}
  _next="${_left}${_insert}${_right}"
  tuish_actor_set "$_id" value "$_next" || return
  local _tuish_input_text=$_insert
  _tuish_input_len
  tuish_actor_set "$_id" cursor_position "$((_cursor + TUISH_TEXT_INPUT_LENGTH))" || return
  _tuish_actor_emit "$_id" data_change "$_next"
}
tuish_text_input_move () {
  local _id=$1 _delta=$2 _value _cursor _len
  case "$_delta" in -*) _tuish_actor_is_uint "${_delta#-}" || return 2;; *) _tuish_actor_is_uint "$_delta" || return 2;; esac
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  local _tuish_input_text=$_value
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  _cursor=$((_cursor + _delta))
  test "$_cursor" -ge 0 || _cursor=0
  test "$_cursor" -le "$_len" || _cursor=$_len
  tuish_actor_set "$_id" cursor_position "$_cursor"
}
tuish_text_input_backspace () {
  local _id=$1 _value _cursor _left _right _next _i _j
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  test "$_cursor" -gt 0 || return 0
  local _tuish_input_text=$_value
  _tuish_input_byte_offset "$_value" "$((_cursor - 1))"; _i=$TUISH_TEXT_INPUT_OFFSET
  _tuish_input_byte_offset "$_value" "$_cursor"; _j=$TUISH_TEXT_INPUT_OFFSET
  _left=${_value:0:$_i}; _right=${_value:$_j}
  _next="${_left}${_right}"
  tuish_actor_set "$_id" value "$_next" || return
  tuish_actor_set "$_id" cursor_position "$((_cursor - 1))" || return
  _tuish_actor_emit "$_id" data_change "$_next"
}
tuish_text_input_delete () {
  local _id=$1 _value _cursor _left _right _next _len _i _j
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  local _tuish_input_text=$_value
  _tuish_input_len; _len=$TUISH_TEXT_INPUT_LENGTH
  test "$_cursor" -lt "$_len" || return 0
  _tuish_input_byte_offset "$_value" "$_cursor"; _i=$TUISH_TEXT_INPUT_OFFSET
  _tuish_input_byte_offset "$_value" "$((_cursor + 1))"; _j=$TUISH_TEXT_INPUT_OFFSET
  _left=${_value:0:$_i}; _right=${_value:$_j}
  _next="${_left}${_right}"
  tuish_actor_set "$_id" value "$_next" || return
  _tuish_actor_emit "$_id" data_change "$_next"
}
tuish_text_input_paste () { tuish_text_input_insert "$1" "${TUISH_PASTE:-${2:-}}"; }
tuish_text_input_focus () {
  local _id=$1 _state=${2:-1}
  case "$_state" in 0|1) ;; *) return 2;; esac
  tuish_actor_set "$_id" focus_state "$_state" || return
  if test "$_state" -eq 1; then _tuish_actor_emit "$_id" on_focus ''; else _tuish_actor_emit "$_id" on_blur ''; fi
}
tuish_text_input_validate () {
  local _id=$1 _fn=${2:-} _value _status=valid
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  if test -n "$_fn"; then
    command -v "$_fn" >/dev/null 2>&1 || return 3
    "$_fn" "$_value" || _status=invalid
  fi
  tuish_actor_set "$_id" validation "$_status" || return
  _tuish_actor_emit "$_id" on_validate "$_status"
  test "$_status" = valid
}
tuish_text_input_render () {
  local _id=$1 _value _mask _placeholder _focus _shown _cursor _left _right
  tuish_actor_get "$_id" value || return; _value=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" mask_char || return; _mask=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" placeholder || return; _placeholder=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" focus_state || return; _focus=$TUISH_ACTOR_VALUE
  tuish_actor_get "$_id" cursor_position || return; _cursor=$TUISH_ACTOR_VALUE
  if test -z "$_value"; then _shown=$_placeholder
  elif test -n "$_mask"; then
    local _tuish_input_text=$_value
    _tuish_input_len; tuish_str_repeat "$_mask" "$TUISH_TEXT_INPUT_LENGTH"; _shown=$TUISH_SREPEATED
  else _shown=$_value; fi
  printf '%s' "$_shown"
  test "$_focus" -eq 1 && printf ' [cursor:%s]' "$_cursor"
}
