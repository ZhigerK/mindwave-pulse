#!/bin/bash
# Enforce UTF-8 in Windows environments (Git Bash, MSYS2)
chcp 65001 > /dev/null 2>&1 || true

# End-to-end integration test for CourseContextManager

BASE_URL="http://localhost:4000/api/v1/context"

echo "========================================="
echo "1. Health Check"
echo "========================================="
curl -s -X GET "http://localhost:4000/health"
echo -e "\n\n"

echo "========================================="
echo "2. Bulk Sync (Contract 4) - Creating Course"
echo "========================================="
curl -s -X POST "$BASE_URL/sync-course" -H "Content-Type: application/json; charset=utf-8" -d '{
  "course_id": "course_101",
  "entities": [
    { "node_id": "course_101", "node_type": "course", "parent_id": null, "content": "Цель курса: освоить Node.js и графовые БД", "metadata": {"title": "Backend RAG Course"} },
    { "node_id": "mod_1", "node_type": "module", "parent_id": "course_101", "content": "Основы графов", "metadata": {"title": "Модуль 1"} },
    { "node_id": "mod_2", "node_type": "module", "parent_id": "course_101", "content": "Векторный поиск", "metadata": {"title": "Модуль 2"} },
    { "node_id": "les_1", "node_type": "lesson", "parent_id": "mod_1", "content": "Урок про узлы и связи (Nodes and Edges).", "metadata": {"title": "Урок 1.1"} }
  ]
}'
echo -e "\n\n"

echo "========================================="
echo "3. Single Node Upsert (Contract 1) - Adding Material"
echo "========================================="
curl -s -X POST "$BASE_URL/nodes" -H "Content-Type: application/json; charset=utf-8" -d '{
  "action": "upsert",
  "node_id": "mat_1",
  "node_type": "material",
  "parent_id": "les_1",
  "content": "В графовых базах данных, таких как Neo4j, связи так же важны, как и сами сущности. Это позволяет быстро обходить дерево.",
  "metadata": {"title": "Текст к уроку 1.1"}
}'
echo -e "\n\n"

echo "========================================="
echo "4. Retrieval (Contract 2) - Hybrid RAG Context"
echo "========================================="
curl -s -X POST "$BASE_URL/retrieve" -H "Content-Type: application/json; charset=utf-8" -d '{
  "current_node_id": "les_1",
  "task_type": "generate_test",
  "user_prompt": "Составь 3 сложных вопроса по базам данных",
  "context_depth": {
    "up": 2,
    "down": 1
  }
}'
echo -e "\n\n"

echo "========================================="
echo "5. Edges Move (Contract 3) - Moving Lesson to Module 2"
echo "========================================="
curl -s -X POST "$BASE_URL/edges" -H "Content-Type: application/json; charset=utf-8" -d '{
  "action": "move",
  "node_id": "les_1",
  "new_parent_id": "mod_2"
}'
echo -e "\n\n"

echo "========================================="
echo "Testing Completed."
echo "========================================="
