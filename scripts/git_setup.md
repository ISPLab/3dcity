Добавление Git LFS в проект 3DCityDB
Git LFS (Large File Storage) — это расширение Git, которое позволяет эффективно работать с большими файлами (например, 3D-моделями, текстурами или наборами данных). Вот как добавить Git LFS в ваш проект:
Шаг 1: Установка Git LFS
Для Linux:
Apply to git_settings...
Run
install
Для macOS:
Apply to git_settings...
Run
install
Для Windows:
Скачайте и установите Git LFS с официального сайта: https://git-lfs.github.com/
Или используйте Chocolatey: choco install git-lfs
После установки откройте командную строку и выполните: git lfs install
Шаг 2: Настройка Git LFS в вашем репозитории
Шаг 3: Добавление .gitattributes в репозиторий
Git LFS создаст файл .gitattributes, который нужно добавить в репозиторий:
Шаг 4: Добавление файлов в репозиторий
Теперь вы можете добавлять большие файлы обычным способом:
Apply to git_settings...
Run
push
Шаг 5: Обновление скриптов развертывания
Чтобы все пользователи вашего проекта могли корректно получать файлы через Git LFS, обновите файл README.md и скрипты развертывания:
fi
Шаг 6: Обновление README.md
Добавьте информацию о Git LFS в README.md:
Client
Git LFS значительно упростит работу с большими файлами моделей в вашем проекте, позволяя эффективно хранить их в репозитории и получать только при необходимости.