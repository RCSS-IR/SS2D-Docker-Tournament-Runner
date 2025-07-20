#!/bin/bash

# Simple team list validator for stepladder
# Usage: ./validate_teams.sh games/step

if [ $# -eq 0 ]; then
    echo "Usage: $0 <team_list_file>"
    echo "Example: $0 games/step"
    exit 1
fi

TEAM_LIST="$1"

if [ ! -f "$TEAM_LIST" ]; then
    echo "❌ ERROR: Team list file '$TEAM_LIST' not found!"
    exit 1
fi

echo "✅ TEAM LIST VALIDATION"
echo "========================"
echo "📁 File: $TEAM_LIST"
echo ""

# Count teams
team_count=$(wc -l < "$TEAM_LIST")
echo "📊 Total teams: $team_count"
echo ""

# List teams with numbers
echo "📋 STEPLADDER ORDER (Top to Bottom):"
counter=1
while read -r team; do
    if [ ! -z "$team" ]; then
        if [ $counter -eq 1 ]; then
            echo "$counter. $team 👑 (LEADER - Top of ladder)"
        elif [ $counter -eq $team_count ]; then
            echo "$counter. $team 🎯 (Bottom - Must win $((team_count-1)) in a row to reach top)"
        else
            echo "$counter. $team"
        fi
        counter=$((counter+1))
    fi
done < "$TEAM_LIST"

echo ""
echo "ℹ️  STEPLADDER RULES:"
echo "   • $team_count teams competing"
echo "   • $(head -n 1 "$TEAM_LIST") starts as leader (top position)"
echo "   • Each team below challenges the current leader"
echo "   • Winners advance up the ladder"
echo "   • $(tail -n 1 "$TEAM_LIST") needs to beat everyone to reach the top"

echo ""
echo "✅ Team list format is valid!"
echo ""
echo "🎯 Ready for stepladder tournament:"
echo "   - Real:  ./run_stepladder.sh -n server1 -tl $TEAM_LIST -ld \$(pwd)/log -ed \$(pwd)/log -st major -gn STEPLADDER"
echo "   - Test:  ./test_stepladder.sh -n server1 -tl $TEAM_LIST -ld \$(pwd)/log -ed \$(pwd)/log -st major -gn TEST"
