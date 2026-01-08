#!/bin/bash
# List all files created in the SaaS backend project
# Conceived by Romuald Członkowski - www.aiadvisors.pl/en

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          UGC SaaS Backend - All Created Files                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

BASE_DIR="/home/user/n8n-skills/saas-backend"

echo "📂 Base Directory: $BASE_DIR"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 ROOT FILES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$BASE_DIR"/*.md 2>/dev/null | awk '{print "   ", $9, "(" $5 ")"}'
ls -lh "$BASE_DIR"/*.txt 2>/dev/null | awk '{print "   ", $9, "(" $5 ")"}'
ls -lh "$BASE_DIR"/.env.example 2>/dev/null | awk '{print "   ", $9, "(" $5 ")"}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗄️  DATABASE MIGRATIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$BASE_DIR"/supabase/migrations/*.sql 2>/dev/null | awk '{print "   ", $9, "(" $5 ")"}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  N8N WORKFLOWS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$BASE_DIR"/workflows/*.json 2>/dev/null | awk '{print "   ", $9, "(" $5 ")"}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 DOCUMENTATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$BASE_DIR"/docs/*.md 2>/dev/null | awk '{print "   ", $9, "(" $5 ")"}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 STATISTICS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL_FILES=$(find "$BASE_DIR" -type f \( -name "*.md" -o -name "*.sql" -o -name "*.json" -o -name "*.txt" -o -name ".env.example" \) | wc -l)
TOTAL_SIZE=$(du -sh "$BASE_DIR" | awk '{print $1}')
TOTAL_LINES=$(find "$BASE_DIR" -type f \( -name "*.md" -o -name "*.sql" -o -name "*.json" -o -name "*.txt" \) -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')

echo "   Total Files: $TOTAL_FILES"
echo "   Total Size: $TOTAL_SIZE"
echo "   Total Lines: $TOTAL_LINES"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 DETAILED FILE LIST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

find "$BASE_DIR" -type f \( -name "*.md" -o -name "*.sql" -o -name "*.json" -o -name "*.txt" -o -name ".env.example" \) | sort | while read file; do
    SIZE=$(ls -lh "$file" | awk '{print $5}')
    LINES=$(wc -l < "$file" 2>/dev/null || echo "0")
    RELATIVE=$(echo "$file" | sed "s|$BASE_DIR/||")
    echo "   📄 $RELATIVE"
    echo "      Size: $SIZE | Lines: $LINES"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All files are in: $BASE_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Conceived by Romuald Członkowski - www.aiadvisors.pl/en"
