#!/bin/bash

validate_git_url() {
    local url=$1
    if [[ "$url" =~ ^git@.+\.git$ ]]; then
        return 0
    else
        return 1
    fi
}

while true; do
    read -p "Введите URL Git-репозитория ( git@github.com:user/repo.git): " REPO_URL
    
    if validate_git_url "$REPO_URL"; then
        break
    else
        echo "Ошибка: Введите верный форма git@github.com:user/repo.git :"
    fi
done

REPO_NAME=$(basename "$REPO_URL" .git)
TEMP_DIR=$(mktemp -d)

echo "Клонируем репозиторий $REPO_NAME..."
git clone --quiet "$REPO_URL" "$TEMP_DIR" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось клонировать репозиторий" >&2
    rm -rf "$TEMP_DIR"
    exit 1
fi

cd "$TEMP_DIR" || exit

LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)

if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="v0.0.0"
    echo "В репозитории нет тегов. Начинаем с $LATEST_TAG"
fi

TAG_COMMIT=$(git rev-list -n 1 "$LATEST_TAG" 2>/dev/null)
HEAD_COMMIT=$(git rev-parse HEAD)

if [ "$TAG_COMMIT" == "$HEAD_COMMIT" ]; then
    echo "Нет изменений после последнего тега $LATEST_TAG"
    cd ..
    rm -rf "$TEMP_DIR"
    exit 0
fi

echo "Обнаружены изменения после тега $LATEST_TAG"

VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')
IFS='.' read -r -a VERSION_PARTS <<< "$VERSION"

MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

NEW_PATCH=$((PATCH + 1))
NEW_TAG="v${MAJOR}.${MINOR}.${NEW_PATCH}"

echo "Создаем новый тег: $NEW_TAG"
git tag -a "$NEW_TAG" -m "Release $NEW_TAG" >/dev/null
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось создать тег $NEW_TAG" >&2
    cd ..
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Отправляем тег в удаленный репозиторий..."
git push origin "$NEW_TAG" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось отправить тег $NEW_TAG" >&2
    cd ..
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Успешно создан и отправлен новый тег: $NEW_TAG"

cd ..
rm -rf "$TEMP_DIR"
echo "Временная директория удалена"
