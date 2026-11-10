#!/bin/sh

# SPDX-License-Identifier: ISC
set -uf
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$TESTS_DIR/lib/test_framework.sh"
. "$TESTS_DIR/../src/actor.sh"
. "$TESTS_DIR/../src/split_view.sh"

_SPLIT_EVENT=''
_split_event () { _SPLIT_EVENT="$2:$1"; }

printf 'Unit tests: SplitView Actor\n'

tuish_split_view_create layout horizontal 100 30 60 2
tuish_split_view_add_pane layout navigation Navigation
tuish_split_view_add_pane layout content Content
tuish_actor_on layout focus _split_event
tuish_actor_on layout resize _split_event
tuish_actor_on layout child_exit _split_event
tuish_actor_on layout render _split_event

_geometry="$(tuish_split_view_layout layout)"
assert_contains "$_geometry" 'navigation|1|1|58|30' 'horizontal split computes first pane from ratio'
assert_contains "$_geometry" 'content|1|61|40|30' 'horizontal split places second pane after gap'
tuish_split_view_focus layout content
tuish_actor_get layout active_pane
assert_eq "$TUISH_ACTOR_VALUE" content 'focus is stored by stable pane ID'
assert_eq "$_SPLIT_EVENT" 'content:layout' 'focus callback receives pane ID'

tuish_split_view_set_ratio layout 70
_geometry="$(tuish_split_view_layout layout)"
assert_contains "$_geometry" 'navigation|1|1|68|30' 'ratio update recalculates primary width'
assert_contains "$_geometry" 'content|1|71|30|30' 'ratio update recalculates secondary position'

tuish_split_view_resize layout 80 24
tuish_actor_get layout width
assert_eq "$TUISH_ACTOR_VALUE" 80 'resize updates available width'
assert_eq "$_SPLIT_EVENT" '80x24:layout' 'layout callback remains deterministic'
_geometry="$(tuish_split_view_layout layout)"
assert_contains "$_geometry" 'navigation|1|1|54|24' 'resize recalculates primary geometry'
assert_contains "$_geometry" 'content|1|57|24' 'resize recalculates secondary geometry'

tuish_split_view_set_constraints layout 20 20
_status=0
tuish_split_view_resize layout 30 20 || _status=$?
assert_eq "$_status" 2 'resize rejects geometry below combined minimum sizes'
tuish_split_view_resize layout 80 24
_status=0
tuish_split_view_set_ratio layout 0 || _status=$?
assert_eq "$_status" 2 'zero ratio is rejected'
_status=0
tuish_split_view_set_gap layout 21 || _status=$?
assert_eq "$_status" 2 'gap above configured maximum is rejected'
_status=0
tuish_split_view_add_pane layout third Third || _status=$?
assert_eq "$_status" 2 'more than two panes are rejected'
_status=0
tuish_split_view_focus layout missing || _status=$?
assert_eq "$_status" 4 'unknown pane focus is rejected'

tuish_split_view_pointer layout 20 5
assert_eq "$TUISH_SPLIT_VIEW_HIT" navigation 'pointer hit-testing resolves first pane'
tuish_split_view_pointer layout 60 5
assert_eq "$_SPLIT_EVENT" 'content:layout' 'pointer focus emits focus callback'
tuish_split_view_child_exit layout navigation
tuish_actor_get layout pane_count
assert_eq "$TUISH_ACTOR_VALUE" 1 'child exit removes pane from active layout'
tuish_actor_get layout active_pane
assert_eq "$TUISH_ACTOR_VALUE" content 'child exit transfers focus to remaining pane'
_geometry="$(tuish_split_view_layout layout)"
assert_contains "$_geometry" 'content|1|1|80|24' 'remaining pane expands to fill the available region'

tuish_split_view_create stacked vertical 40 20 25 1
tuish_split_view_add_pane stacked top Top
tuish_split_view_add_pane stacked bottom Bottom
_geometry="$(tuish_split_view_layout stacked)"
assert_contains "$_geometry" 'top|1|1|40|4' 'vertical split computes first pane height'
assert_contains "$_geometry" 'bottom|6|1|40|15' 'vertical split stacks second pane after gap'
_status=0
tuish_split_view_resize stacked 40 4 || _status=$?
assert_eq "$_status" 2 'vertical resize enforces minimum heights'

tuish_actor_action stacked ratio 60
tuish_actor_get stacked split_ratio
assert_eq "$TUISH_ACTOR_VALUE" 60 'Actor action delegates ratio changes to SplitView'
tuish_actor_destroy layout
tuish_actor_destroy stacked
tuish_actor_count
assert_eq "$TUISH_ACTOR_COUNT" 0 'SplitView Actor cleanup removes registry data'

test_summary
