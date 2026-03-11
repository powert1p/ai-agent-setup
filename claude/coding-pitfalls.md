# Косяки при написании кода — и как их обходить

> **Часть 1** — ИИ-специфичные косяки: галлюцинации, деградация, потеря контекста.
> **Часть 2** — Говнокодинг в целом: code smells, anti-patterns, security, техдолг.
>
> Это не теория. Это реальные паттерны ошибок, подтверждённые исследованиями и статистикой 2024-2026.

---

# Часть 1: ИИ-специфичные косяки

> ИИ-код содержит в **1.7x больше багов** чем человеческий (10.83 issues/PR vs 6.45).
> 45% ИИ-кода содержит уязвимости из OWASP Top-10. Только 48% ревьювят ИИ-код перед коммитом.

---

## 1. Галлюцинации пакетов (Slopsquatting)

### Что происходит
ИИ рекомендует пакеты, которых **не существует**. 20% рекомендованных пакетов — выдуманные. Атакующие регистрируют эти имена и кладут туда малварь.

### Пример
```bash
# ИИ советует:
npm install async-validator-lite   # ← не существует
pip install flask-restful-utils    # ← не существует

# Атакующий регистрирует async-validator-lite с вредоносным кодом
# Разработчик ставит по совету ИИ → supply chain attack
```

### Как обходить
- **Всегда проверяй пакет** перед установкой: существует ли он на npm/PyPI, сколько скачиваний, когда создан
- Если пакет создан недавно и мало звёзд — подозрительно
- Используй `npm audit` / `pip-audit` после установки
- Не доверяй "рекомендациям" ИИ по пакетам слепо — проверяй руками

---

## 2. Выдуманные API и методы

### Что происходит
ИИ выдумывает методы, которые звучат правдоподобно, но не существуют. 30% API-рекомендаций от ChatGPT — галлюцинации.

### Пример
```python
# ИИ пишет:
response = requests.get(url, validate_ssl=True)   # ← нет такого параметра
#                             ^^^^^^^^^^^^
# Правильно: verify=True

# Или:
df.to_csv("file.csv", encoding_errors="replace")  # ← не существует
```

```dart
// ИИ пишет:
final result = await dio.get('/api/data',
    onProgress: (count, total) => print('$count/$total'));
//  ^^^^^^^^^^  — такого параметра у dio.get() нет
```

### Как обходить
- **Читай документацию**, а не верь ИИ на слово — особенно для незнакомых библиотек
- Если ИИ использует метод которого ты не знаешь — загугли прежде чем коммитить
- Хорошая новость: эти ошибки видны сразу при компиляции/запуске
- Проси ИИ дать ссылку на документацию — если не может, скорее всего выдумал

---

## 3. Безопасность (2.74x больше XSS, 1.88x хуже пароли)

### Что происходит
ИИ генерирует уязвимый код потому что видел такие паттерны миллионы раз в open-source (где безопасность часто игнорируется). После 5 итераций промптинга уязвимостей становится на 37% больше.

### Примеры

**SQL Injection:**
```python
# ИИ пишет:
query = f"SELECT * FROM users WHERE name = '{user_input}'"  # 💀
cursor.execute(query)

# Правильно:
cursor.execute("SELECT * FROM users WHERE name = %s", (user_input,))
```

**XSS:**
```javascript
// ИИ пишет:
element.innerHTML = userComment;  // 💀 — любой скрипт выполнится

// Правильно:
element.textContent = userComment;
```

**Пароли в коде:**
```go
// ИИ пишет:
jwtSecret := "mysecret123"  // 💀

// Правильно:
jwtSecret := os.Getenv("JWT_SECRET")
```

**Auth без верификации:**
```go
// ИИ пишет:
// TODO: verify Telegram hash in production
func TelegramLogin(w http.ResponseWriter, r *http.Request) {
    // принимаем всё без проверки 💀
}
```

### Как обходить
- **Никаких TODO для безопасности** — делай сразу или не мержи
- Всегда параметризуй SQL (prepared statements)
- Никогда `innerHTML` с пользовательским вводом — только `textContent`
- Секреты только из env переменных, никогда в коде
- Проверяй auth/hash/подписи — не "потом", а сейчас
- Прогоняй `go vet`, `flutter analyze`, линтеры после каждой ИИ-сессии

---

## 4. Happy Path — игнорирование edge cases

### Что происходит
ИИ отлично пишет "счастливый путь" — когда всё идеально. Но пропускает: null, пустые массивы, нулевые значения, отрицательные числа, таймауты, сетевые ошибки.

### Пример
```go
// ИИ пишет:
func GetUser(id int) *User {
    user, _ := repo.FindByID(id)  // 💀 ошибка проглочена
    return user                    // может быть nil → паника при обращении
}

// Правильно:
func GetUser(id int) (*User, error) {
    user, err := repo.FindByID(id)
    if err != nil {
        return nil, fmt.Errorf("get user %d: %w", id, err)
    }
    if user == nil {
        return nil, ErrNotFound
    }
    return user, nil
}
```

```dart
// ИИ пишет:
final items = response.data['items'] as List;  // 💀 что если null?
final first = items[0];                         // 💀 что если пустой?

// Правильно:
final items = (response.data['items'] as List?) ?? [];
if (items.isEmpty) return;
final first = items[0];
```

### Как обходить
- После каждого ИИ-сниппета спрашивай: **"а что если null? а если пусто? а если ошибка?"**
- Проверяй: пустой ввод, null, 0, отрицательные числа, максимальные значения
- Тестируй не только happy path — пиши тесты на ошибки
- Не глотай ошибки: `_, _ := something()` — красный флаг

---

## 5. Over-engineering и фантомные баги

### Что происходит
80-90% ИИ-кода — гиперспецифичные одноразовые решения. 20-30% содержат "фантомные баги": обработку ошибок для ситуаций, которые не могут произойти.

### Пример
```python
# ИИ добавляет "на всякий случай":
def get_username(user):
    if user is None:
        return "Unknown"
    if not isinstance(user, dict):        # фантомный баг — user всегда dict
        return "Unknown"
    if 'name' not in user:                # фантомный баг — name всегда есть
        return "Unknown"
    if not isinstance(user['name'], str): # фантомный баг — name всегда str
        return "Unknown"
    if len(user['name']) == 0:
        return "Unknown"
    return user['name']

# Достаточно:
def get_username(user):
    return user.get('name') or "Unknown"
```

```dart
// ИИ создаёт:
class UserDataManager {
  final UserRepository _repo;
  final UserCache _cache;
  final UserValidator _validator;
  final UserTransformer _transformer;
  final UserLogger _logger;
  // ... для одного CRUD экрана 💀
}

// Достаточно:
class UserRepository {
  Future<User?> getById(int id) => api.get('/users/$id');
}
```

### Как обходить
- **Удаляй лишнее** — если проверка не может сработать, убери её
- Не создавай абстракции "на будущее" — три строки лучше чем преждевременная абстракция
- Спрашивай: "какую реальную проблему решает эта проверка?"
- Валидируй только на границах системы (пользовательский ввод, внешние API)

---

## 6. Архитектурная деградация

### Что происходит
ИИ по дефолту пишет связанный монолитный код. 40-50% ИИ-кода нарушает архитектурные слои — прямой SQL в handler-ах, API-вызовы в UI, бизнес-логика в контроллерах.

### Пример
```go
// ИИ пишет handler который делает ВСЁ:
func CreateOrder(w http.ResponseWriter, r *http.Request) {
    var req OrderRequest
    json.NewDecoder(r.Body).Decode(&req)           // парсинг HTTP

    db.Exec("INSERT INTO orders ...", req.Items)    // 💀 SQL в handler

    total := 0.0
    for _, item := range req.Items {
        total += item.Price * float64(item.Qty)     // 💀 бизнес-логика в handler
        if item.Qty > 100 {
            total *= 0.9                             // 💀 скидка зашита в handler
        }
    }

    sendEmail(req.Email, "Order confirmed")          // 💀 side-effect в handler
    json.NewEncoder(w).Encode(map[string]float64{"total": total})
}

// Правильно — разделение слоёв:
// handler → service → repository
func CreateOrder(w http.ResponseWriter, r *http.Request) {
    var req OrderRequest
    if err := readJSON(r, &req); err != nil { ... }

    order, err := orderService.Create(req)  // вся логика в сервисе
    if err != nil { ... }

    writeJSON(w, http.StatusCreated, order)
}
```

### Как обходить
- **Задавай архитектуру ДО генерации** — скажи ИИ: "handler не пишет SQL, service не знает про HTTP"
- Имей шаблон проекта с правильными слоями заранее
- Ревьювь каждый файл: "этот код в правильном слое?"
- Не позволяй ИИ "для удобства" мешать слои

---

## 7. Silent failures (код работает, но врёт)

### Что происходит
Новый тренд 2025: ИИ генерирует код без синтаксических ошибок, который **тихо возвращает неправильные данные**. Убирает safety checks чтобы не было крашей. Создаёт фейковый output.

### Пример
```python
# ИИ пишет:
def get_revenue(start_date, end_date):
    try:
        result = db.query("SELECT SUM(amount) FROM orders WHERE ...")
        return result
    except:
        return 0.0  # 💀 тихо возвращает 0 вместо ошибки
                     # менеджер видит "доход = 0" и паникует
                     # или хуже — не замечает и принимает решения на фейковых данных
```

```go
// ИИ пишет:
func FetchUserData(id int) UserData {
    resp, err := http.Get(fmt.Sprintf("/api/users/%d", id))
    if err != nil {
        return UserData{Name: "Unknown", Balance: 0}  // 💀 фейковые данные
    }
    // ...
}
```

### Как обходить
- **Ошибка должна быть видна** — возвращай error, не дефолтное значение
- `catch` без конкретного типа исключения — красный флаг
- Если метод может упасть, он должен возвращать `(result, error)` или бросать исключение
- Логируй ошибки, не глотай: `log.Printf("[ERROR] ...")` минимум

---

## 8. Copy-paste вместо переиспользования

### Что происходит
ИИ не знает что в проекте уже есть нужная функция. Каждый раз пишет заново. В итоге один и тот же код в 3-5 местах, баг фиксишь в одном — забываешь про остальные.

### Пример
```dart
// ИИ пишет в practice_screen.dart:
String _fmtTime(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

// И такой же в exam_screen.dart:
String _fmtTime(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

// И в diagnostic_screen.dart:
String _fmtTime(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

// Правильно — один раз в shared/utils/formatters.dart:
String formatTime(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
```

### Как обходить
- Перед генерацией скажи ИИ: **"посмотри существующие утилиты в shared/"**
- Если видишь похожий код второй раз — выноси в shared
- Делай `grep` по проекту на дублирование после ИИ-сессии
- Давай ИИ контекст: "в проекте есть formatTime() в shared/utils/formatters.dart — используй его"

---

## 9. Потеря контекста на длинных сессиях

### Что происходит
Чем длиннее разговор с ИИ, тем больше он забывает. Архитектурные решения с начала сессии исчезают. Код из шага 10 противоречит коду из шага 1. Copilot с полным доступом к файлам всё равно генерирует 60% спекулятивного контента.

### Пример
```
Шаг 1: "Используй repository pattern, handler не пишет SQL"
Шаг 5: handler/practice.go — ИИ пишет SQL прямо в handler 💀
        (забыл что мы договорились про repository)

Шаг 1: "JWT claims должны быть типизированными"
Шаг 8: ИИ снова пишет jwt.MapClaims 💀
```

### Как обходить
- **Держи архитектурные правила в файле** (CLAUDE.md, RULES.md) — ИИ читает его каждый раз
- Разбивай длинные задачи на отдельные сессии
- Напоминай ключевые решения: "помни — handler не пишет SQL"
- После длинной сессии — полный ревью всех изменений, не доверяй "уже проверено"

---

## 10. Проблема 80% (Addy Osmani)

### Что происходит
ИИ быстро генерирует 70-80% кода (scaffolding, очевидные паттерны). Но оставшиеся 20-30% — интеграция, edge cases, безопасность, продакшн-готовность — занимают столько же времени как раньше. Разработчики думают что задача почти готова, а на самом деле половина работы впереди.

### Реальность
```
С ИИ:
████████████████░░░░ 80% за 10 минут  ← "почти готово!"
████████████████████ 100% за 2 часа   ← edge cases, security, тесты

Без ИИ:
████████████████████ 100% за 3 часа   ← предсказуемо

Экономия: 1 час. Не 2 часа 50 минут как кажется.
```

### Как обходить
- **Не путай scaffolding с готовым кодом** — 80% сгенерировано ≠ 80% сделано
- Планируй время на ревью, тесты, интеграцию — ИИ их не заменяет
- Потрать 70% времени на ТЗ и спецификацию, 30% на генерацию (совет Osmani)
- Используй ИИ для рутины, а сложные решения принимай сам

---

## 11. Comprehension debt (код быстрее чем ревью)

### Что происходит
ИИ генерирует код быстрее чем человек может его прочитать и понять. 38% разработчиков говорят что ревьювить ИИ-код **сложнее** чем человеческий. В итоге код, который никто не понимает, попадает в прод.

### Пример
```
Понедельник: ИИ сгенерировал 500 строк за 15 минут
Вторник: нужно пофиксить баг → 2 часа разбираться что этот код делает
Среда: другой разработчик трогает этот файл → ломает всё, потому что не понял логику
Четверг: "давай перепишем этот модуль"
```

### Как обходить
- **Не коммить код который не понимаешь** — даже если он работает
- Читай каждую строку перед коммитом — не просматривай, а читай
- Если не можешь объяснить коллеге что делает функция — не мержи
- Лучше 50 понятных строк чем 200 "магических"
- Проси ИИ объяснить сложные участки перед коммитом

---

## 12. Итеративная деградация

### Что происходит
Парадокс: чем больше итераций промптинга, тем **хуже** код. После 5 итераций — на 37% больше критических уязвимостей. ИИ пытается удовлетворить все предыдущие замечания и ломает то что работало.

### Пример
```
Итерация 1: "Напиши auth handler"        → работает, но без валидации
Итерация 2: "Добавь валидацию"            → добавил, но сломал error handling
Итерация 3: "Почини error handling"       → починил, но убрал rate limiting
Итерация 4: "Верни rate limiting"         → вернул, но ввёл SQL injection
Итерация 5: "Почини SQL injection"        → починил, но теперь auth вообще не работает
```

### Как обходить
- **Максимум 2-3 итерации** на один кусок кода, потом — ручной ревью
- Если ИИ ходит по кругу — остановись, прочитай код сам, пойми проблему
- Тесты после каждой итерации, не только после последней
- Не проси ИИ "просто починить" — объясни что именно не так и почему

---

# Часть 2: Говнокодинг в целом

> Стоимость плохого кода в США — **$2.41 трлн в год** (CISQ 2024).
> Разработчики тратят **33% рабочего времени** на технический долг (Stripe 2023).
> **70% символов** в коде — это имена переменных. Плохие имена = непонимание.
> **70% кода** в проектах — скопированный, 17% клонов содержат баги.

---

## 13. God Object / God Class

### Что это
Один класс/struct который делает **всё**: парсит HTTP, ходит в БД, считает бизнес-логику, шлёт email-ы. 1000+ строк, 50+ методов. Нарушает Single Responsibility Principle.

### Почему так делают
"Проще добавить метод в существующий класс чем создавать новый". Лень + отсутствие архитектуры.

### Пример
```go
// God Object — handler который делает ВСЁ:
type AppHandler struct {
    DB          *sqlx.DB
    Redis       *redis.Client
    Mailer      *smtp.Client
    S3          *s3.Client
    Logger      *log.Logger
    JWTSecret   string
    BotToken    string
    // ... ещё 15 полей
}

func (h *AppHandler) CreateUser(w http.ResponseWriter, r *http.Request) { ... }
func (h *AppHandler) DeleteUser(w http.ResponseWriter, r *http.Request) { ... }
func (h *AppHandler) CreateOrder(w http.ResponseWriter, r *http.Request) { ... }
func (h *AppHandler) SendEmail(to, subject, body string) error { ... }
func (h *AppHandler) UploadFile(data []byte) (string, error) { ... }
func (h *AppHandler) CalculateDiscount(order Order) float64 { ... }
func (h *AppHandler) VerifyAuth(token string) (*Claims, error) { ... }
// ... ещё 30 методов

// Правильно — разделение по ответственности:
type UserHandler struct { svc *UserService }
type OrderHandler struct { svc *OrderService }
type UserService struct { repo *UserRepo; mailer *Mailer }
type OrderService struct { repo *OrderRepo; pricing *PricingService }
```

### Последствия
- Поддерживать на **30-40% дольше** (Fowler, Refactoring)
- Один баг в God Object может сломать **все** фичи
- Невозможно тестировать изолированно — нужно мокать 15 зависимостей
- Merge conflicts на каждом PR — все трогают один файл

### Как избежать
- Один struct = одна ответственность. Handler не считает бизнес-логику
- Если файл > 300 строк — пора разбивать
- Если struct имеет > 5 зависимостей — слишком много ответственности

---

## 14. Спагетти-код и глубокая вложенность

### Что это
`if` внутри `if` внутри `for` внутри `switch`. Cyclomatic complexity > 10. Код невозможно прочитать без дебаггера.

### Статистика
- Высокая вложенность **коррелирует с количеством дефектов** (Semantic Scholar, 2023)
- Функции с complexity > 10 содержат на **25% больше багов**
- Clean Code рекомендует: **максимум 20 строк на функцию**

### Пример
```go
// Спагетти:
func ProcessOrder(order Order) error {
    if order.Items != nil {
        for _, item := range order.Items {
            if item.Qty > 0 {
                if item.Price > 0 {
                    stock, err := getStock(item.ID)
                    if err == nil {
                        if stock >= item.Qty {
                            if item.Discount > 0 {
                                // ... ещё 3 уровня вложенности
                            } else {
                                // ...
                            }
                        } else {
                            return ErrOutOfStock
                        }
                    } else {
                        return err
                    }
                }
            }
        }
    }
    return nil
}

// Правильно — early return + guard clauses:
func ProcessOrder(order Order) error {
    if len(order.Items) == 0 {
        return ErrEmptyOrder
    }
    for _, item := range order.Items {
        if err := validateItem(item); err != nil {
            return fmt.Errorf("item %s: %w", item.ID, err)
        }
        if err := reserveStock(item); err != nil {
            return fmt.Errorf("stock %s: %w", item.ID, err)
        }
    }
    return nil
}
```

```dart
// Спагетти:
Widget build(BuildContext context) {
  return isLoading
      ? const Center(child: CircularProgressIndicator())
      : error != null
          ? Center(child: Text(error!))
          : items.isEmpty
              ? const Center(child: Text('Пусто'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => items[i].isActive
                      ? ListTile(title: Text(items[i].name))
                      : const SizedBox.shrink(),
                );
}

// Правильно:
Widget build(BuildContext context) {
  if (isLoading) return const Center(child: CircularProgressIndicator());
  if (error != null) return Center(child: Text(error!));
  if (items.isEmpty) return const Center(child: Text('Пусто'));

  final active = items.where((i) => i.isActive).toList();
  return ListView.builder(
    itemCount: active.length,
    itemBuilder: (ctx, i) => ListTile(title: Text(active[i].name)),
  );
}
```

### Как избежать
- **Early return** — выходи из функции как можно раньше
- **Guard clauses** — проверки на невалидные данные в начале функции
- Разбивай на маленькие функции с понятными именами
- Максимум 2-3 уровня вложенности. Больше = рефакторинг

---

## 15. Проглатывание ошибок

### Что это
`catch {}`, `_ = err`, `except: pass`, `|| true`. Код не падает — но **тихо делает неправильные вещи**. Самый опасный антипаттерн.

### Почему так делают
"Чтобы не крашилось". Разработчик не знает что делать с ошибкой и просто игнорирует.

### Пример
```go
// Проглатывание:
func SaveUser(u User) {
    _, _ = db.Exec("INSERT INTO users ...", u.Name, u.Email)  // ошибка игнорируется
    _ = cache.Set("user:"+u.ID, u)                             // тоже
    _ = mailer.Send(u.Email, "Welcome!")                        // и тут
    // Всё "работает", но данные может не сохранились,
    // кэш не обновился, письмо не отправилось
}

// Правильно:
func SaveUser(u User) error {
    if _, err := db.Exec("INSERT INTO users ...", u.Name, u.Email); err != nil {
        return fmt.Errorf("save user to db: %w", err)
    }
    if err := cache.Set("user:"+u.ID, u); err != nil {
        log.Printf("[WARN] cache set failed for user %s: %v", u.ID, err)
        // кэш некритичен — логируем и продолжаем
    }
    if err := mailer.Send(u.Email, "Welcome!"); err != nil {
        log.Printf("[WARN] welcome email failed for %s: %v", u.Email, err)
    }
    return nil
}
```

```python
# Проглатывание:
try:
    data = json.loads(raw_input)
    process(data)
except:          # ловит ВСЁ — включая KeyboardInterrupt, SystemExit
    pass         # и молча игнорирует

# Правильно:
try:
    data = json.loads(raw_input)
except json.JSONDecodeError as e:
    logger.warning("Invalid JSON input: %s", e)
    return default_response()
```

### Красные флаги
- `_ = err` или `_, _ = something()` в Go
- `except: pass` или `except Exception: pass` в Python
- Пустой `catch {}` в Dart/JS
- `|| true` в bash скриптах

### Как избежать
- **Ошибка должна быть видна**: вернуть error, залогировать, или бросить исключение
- Разделяй критичные и некритичные ошибки: БД = fatal, кэш = warning
- Линтер `errcheck` для Go ловит игнорированные ошибки
- `analysis_options.yaml` в Dart: `unawaited_futures: error`

---

## 16. SQL и базы данных

### Антипаттерны

**N+1 запросов** — самая частая проблема производительности:
```go
// N+1: 1 запрос на список + N запросов на детали
users, _ := db.Query("SELECT id, name FROM users")
for _, u := range users {
    orders, _ := db.Query("SELECT * FROM orders WHERE user_id = $1", u.ID)
    // 100 юзеров = 101 запрос к БД
}

// Правильно — один JOIN:
rows, _ := db.Query(`
    SELECT u.id, u.name, o.id, o.total
    FROM users u
    LEFT JOIN orders o ON o.user_id = u.id
`)
// 100 юзеров = 1 запрос
```

**Отсутствие индексов:**
```sql
-- Без индекса: full table scan на каждый запрос
SELECT * FROM orders WHERE user_id = 42;  -- сканирует ВСЕ строки

-- С индексом: мгновенно
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

**Нет миграций** — SQL руками в проде:
```bash
# Говнокодинг:
psql -c "ALTER TABLE users ADD COLUMN phone TEXT"  # руками в проде, без версионирования

# Правильно — миграции:
# migrations/003_add_phone.sql
ALTER TABLE users ADD COLUMN phone TEXT;
```

**Хранение всего в JSON:**
```sql
-- Говнокодинг: всё в одном JSON-поле
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    data JSONB  -- имя, email, адрес, заказы — всё тут
);
-- нельзя нормально индексировать, валидировать, JOIN-ить

-- Правильно: нормализованная схема
CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT, email TEXT);
CREATE TABLE addresses (id SERIAL, user_id INT REFERENCES users(id), ...);
```

### Как избежать
- Всегда проверяй `EXPLAIN ANALYZE` для тяжёлых запросов
- Используй миграции (goose, migrate, alembic)
- Индексируй все поля по которым делаешь WHERE, JOIN, ORDER BY
- JSON в SQL — только для действительно неструктурированных данных

---

## 17. Хардкод и магические числа

### Что это
Значения вшитые прямо в код без объяснения. `if status == 3` — что такое 3? `time.Sleep(86400)` — почему именно столько?

### Пример
```go
// Говнокодинг:
func CheckAccess(role int) bool {
    return role >= 3  // что такое 3? Admin? Moderator?
}

func Retry(fn func() error) {
    for i := 0; i < 5; i++ {     // почему 5?
        time.Sleep(2000)           // 2000 чего? мс? нс?
        if fn() == nil { return }
    }
}

// Правильно:
const (
    RoleAdmin     = 3
    MaxRetries    = 5
    RetryInterval = 2 * time.Second
)

func CheckAccess(role int) bool {
    return role >= RoleAdmin
}

func Retry(fn func() error) {
    for i := 0; i < MaxRetries; i++ {
        time.Sleep(RetryInterval)
        if fn() == nil { return }
    }
}
```

```dart
// Говнокодинг:
if (screenWidth > 768) {   // что за 768?
  showDesktopLayout();
}
padding: EdgeInsets.all(16.0),  // почему 16?
fontSize: 14,                    // почему 14?

// Правильно:
class AppBreakpoints {
  static const double tablet = 768;
}
class AppSpacing {
  static const double md = 16.0;
}
class AppFontSize {
  static const double body = 14.0;
}
```

### Как избежать
- Именованные константы с описательными именами
- Конфигурация через env-переменные для значений зависящих от среды
- Если число непонятно без контекста — выноси в `const`

---

## 18. Copy-paste programming

### Статистика
- **70% кода** в проектах — скопированный/клонированный (GitHub study)
- Linux: **190,000** copy-pasted сегментов, **49 багов** найдено в последней версии
- **17% клонов кода содержат дефекты** (CP-Miner)
- В одном Linux-драйвере: **34 из 35 ошибок** — из-за copy-paste

### Пример
```dart
// Один и тот же код в 3 файлах:

// practice_screen.dart:
String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// exam_screen.dart:  (copy-paste)
String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// diagnostic_screen.dart:  (copy-paste, но с багом — забыли padLeft)
String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:$s';  // баг — не форматирует "05" → показывает "5"
}
```

### Почему опасно
- Фикс в одном месте — забываешь про другие
- Баги реплицируются: скопировал код с багом → баг в 5 местах
- Увеличивает размер кодовой базы без пользы

### Как избежать
- DRY (Don't Repeat Yourself) — но не фанатично
- Если видишь одно и то же > 2 раз — выноси в shared utility
- `grep` по проекту на подозрительно похожий код
- Три строки — нормально. Десять одинаковых строк — рефакторинг

---

## 19. Отсутствие тестов и плохие тесты

### Антипаттерны тестирования

**Нет тестов вообще:**
- "Потом напишу" → никогда. Без тестов каждый рефакторинг — рулетка.
- Баг который тест поймал бы за 2 секунды — дебажишь 2 часа в проде.

**Тесты на реализацию, а не на поведение:**
```go
// Плохой тест — зависит от внутренней реализации:
func TestCreateUser(t *testing.T) {
    mock.ExpectExec("INSERT INTO users").
        WithArgs("John", "john@test.com").  // привязан к конкретному SQL
        WillReturnResult(sqlmock.NewResult(1, 1))
    // Если рефакторишь SQL → тест ломается, хотя логика та же
}

// Хороший тест — проверяет поведение:
func TestCreateUser(t *testing.T) {
    svc := NewUserService(testDB)
    user, err := svc.Create("John", "john@test.com")

    if err != nil { t.Fatal(err) }
    if user.Name != "John" { t.Errorf("expected John, got %s", user.Name) }

    // Проверяем что сохранилось, а не КАК сохранилось:
    found, _ := svc.GetByID(user.ID)
    if found.Email != "john@test.com" { t.Error("user not persisted") }
}
```

**Flaky tests** — тесты которые то проходят, то нет:
```go
// Flaky — зависит от времени:
func TestTokenExpiry(t *testing.T) {
    token := GenerateToken(1 * time.Second)
    time.Sleep(1 * time.Second)  // гонка: иногда 999ms, иногда 1001ms
    if !IsExpired(token) { t.Error("should be expired") }
}

// Стабильный:
func TestTokenExpiry(t *testing.T) {
    token := GenerateTokenWithExpiry(time.Now().Add(-1 * time.Second))
    if !IsExpired(token) { t.Error("should be expired") }
}
```

### Как избежать
- Тестируй **поведение**, не реализацию
- Мокай только **внешние границы** (БД, HTTP, файловая система)
- Никаких `time.Sleep` в тестах — используй фиксированное время
- Минимум: тест на happy path + тест на основные ошибки для каждого публичного метода

---

## 20. Безопасность — OWASP / SANS Top 25

### Статистика (2025)
- **#1 SANS 2025**: Cross-Site Scripting (XSS)
- **#2**: SQL Injection
- **#3**: Cross-Site Request Forgery (CSRF)
- **133 новых CVE в день** в 2025 году
- **80% пентестов** находят exploitable misconfigurations (Rapid7)
- **82% cloud инцидентов** — человеческие ошибки конфигурации

### Самые частые ошибки

**Инъекции (SQL, Command, LDAP):**
```go
// Command injection:
func Ping(host string) string {
    out, _ := exec.Command("ping", "-c", "1", host).Output()  // если host = "; rm -rf /"?
    return string(out)
}

// Правильно — валидация:
func Ping(host string) (string, error) {
    if !isValidHostname(host) {
        return "", fmt.Errorf("invalid hostname: %s", host)
    }
    out, err := exec.Command("ping", "-c", "1", host).Output()
    return string(out), err
}
```

**Открытые секреты:**
```yaml
# docker-compose.yml в git:
environment:
  POSTGRES_PASSWORD: "admin123"     # в открытом репозитории
  JWT_SECRET: "mysupersecret"       # любой может подписать JWT
  API_KEY: "sk-1234567890abcdef"    # доступ к платному API
```

**Отсутствие rate limiting:**
```go
// Без rate limit — brute force за 5 минут:
r.Post("/api/auth/login", handler.Login)

// С rate limit:
authLimiter := NewRateLimiter(20, time.Minute)
r.Group(func(r chi.Router) {
    r.Use(authLimiter.Middleware)
    r.Post("/api/auth/login", handler.Login)
})
```

### Как избежать
- **Всегда параметризуй** SQL и команды — никогда строковая конкатенация
- Секреты только в env, никогда в коде/конфигах в git
- `.gitignore`: `.env`, `*.pem`, `credentials.*`
- Rate limiting на auth endpoints
- HTTPS everywhere. CORS правильно настроен

---

## 21. Конкурентность

### Что это
Race conditions, deadlocks, отсутствие синхронизации. Особенно актуально в Go с горутинами.

### Статистика
- Go `crypto/ssh` CVE-2024: **auth bypass** из-за логической ошибки в concurrent коде
- Race conditions — одни из самых сложных багов: **воспроизводятся в 1 из 1000 запусков**

### Пример
```go
// Race condition — счётчик без синхронизации:
var counter int

func Increment() {
    counter++  // НЕ атомарная операция: read → increment → write
}

// 100 горутин вызывают Increment() → counter != 100

// Правильно — вариант 1: Mutex
var (
    mu      sync.Mutex
    counter int
)

func Increment() {
    mu.Lock()
    counter++
    mu.Unlock()
}

// Правильно — вариант 2: atomic
var counter int64

func Increment() {
    atomic.AddInt64(&counter, 1)
}
```

```go
// Deadlock — два mutex-а в разном порядке:
func TransferA(from, to *Account, amount int) {
    from.mu.Lock()  // лочит A
    to.mu.Lock()    // ждёт B → deadlock если другая горутина делает TransferB
    // ...
}

func TransferB(from, to *Account, amount int) {
    from.mu.Lock()  // лочит B
    to.mu.Lock()    // ждёт A → deadlock
}

// Правильно — всегда лочить в одном порядке:
func Transfer(from, to *Account, amount int) {
    first, second := from, to
    if from.ID > to.ID {
        first, second = to, from
    }
    first.mu.Lock()
    second.mu.Lock()
    defer first.mu.Unlock()
    defer second.mu.Unlock()
    // ...
}
```

### Как избежать
- `go test -race ./...` — **всегда** запускай с race detector
- Минимизируй shared state — передавай данные через channels
- Если Mutex нужен — лочи в **одном порядке** везде
- `sync.Once` для однократной инициализации, `sync.Map` для concurrent maps

---

## 22. Именование

### Статистика
- **70% символов** в коде — имена переменных (GitHub study)
- С нормальными именами ошибки находят на **14% быстрее** (University of Hawaii)
- Плохие имена **коррелируют** с низким качеством кода при статическом анализе

### Примеры плохих имён
```go
// Плохо — однобуквенные, аббревиатуры, непонятные:
func proc(d []byte) ([]byte, error) {   // proc? d? что это?
    var r []byte
    for _, b := range d {
        if b > 0x20 {
            r = append(r, b)
        }
    }
    return r, nil
}

// Хорошо:
func removeControlChars(input []byte) ([]byte, error) {
    var cleaned []byte
    for _, char := range input {
        if char > 0x20 {
            cleaned = append(cleaned, char)
        }
    }
    return cleaned, nil
}
```

```dart
// Плохо:
final x = getData();    // x? getData чего?
final tmp = calc(x);    // tmp? calc чего?
setState(() => d = tmp); // d?

// Хорошо:
final studentProfile = fetchStudentProfile();
final masteryLevel = calculateMastery(studentProfile);
setState(() => currentMastery = masteryLevel);
```

### Антипаттерны именования
| Плохо | Проблема | Лучше |
|-------|----------|-------|
| `data`, `info`, `item` | Ни о чём не говорит | `userProfile`, `orderDetails` |
| `temp`, `tmp`, `x` | Непонятно что хранит | `filteredUsers`, `parsedInput` |
| `flag`, `flag2` | Что за флаг? | `isActive`, `hasPermission` |
| `doStuff()` | Что делает? | `sendNotification()` |
| `handleClick()` | Какой клик? | `handleSubmitOrder()` |
| `Manager`, `Helper`, `Utils` | God class с размытой ответственностью | Конкретное имя по задаче |

### Как избежать
- Имя должно **отвечать на вопрос**: что это? зачем? — без чтения реализации
- Длина имени пропорциональна scope: `i` в for loop — ок, `i` в поле struct — нет
- Консистентность: если `getUser` — то и `getOrder`, а не `fetchOrder`
- Bool переменные: `isActive`, `hasAccess`, `canEdit` — с префиксом

---

## 23. Технический долг

### Статистика
- **$2.41 трлн в год** — стоимость плохого софта в США (CISQ 2024)
- **40% IT бюджетов** уходит на техдолг (McKinsey)
- **33% рабочего времени** разработчиков — борьба с техдолгом (Stripe 2023)
- **$3,700-$6,000** техдолга на каждые 1000 строк кода (CAST)
- Компании с высоким техдолгом выпускают фичи на **25-50% медленнее**

### Формы техдолга
```
"Потом пофикшу"        → никогда
"TODO: рефакторинг"    → через 3 года TODO ещё там
"Это временное решение" → прод работает на "временном" 5 лет
"Нет времени на тесты" → время на дебаг x10
"Работает — не трогай" → трогаешь через год и всё ломается
```

### Реальный пример
```go
// Год 1: "быстрое решение"
func GetPrice(product Product) float64 {
    // TODO: перенести в PricingService
    if product.Category == "electronics" {
        return product.BasePrice * 1.2  // наценка 20%
    }
    if product.Category == "food" {
        return product.BasePrice * 1.05
    }
    // ... через год тут 50 if-else
    return product.BasePrice
}

// Год 3: 50 категорий, 3 типа скидок, сезонные цены — всё в одной функции.
// Никто не рефакторил. Цены иногда неправильные. Никто не знает почему.
```

### Как управлять
- **Не допускай**: пиши нормально сразу, не "потом"
- Если TODO — ставь deadline. `// TODO(2025-03): перенести в сервис`
- Выделяй 20% спринта на техдолг — иначе он растёт экспоненциально
- Мерь техдолг: SonarQube, CodeClimate дают конкретные цифры
- Рефакторинг — часть разработки, не "отдельная задача на потом"

---

## 24. Git и деплой антипаттерны

### Коммит секретов
```bash
# Говнокодинг:
git add .env                  # пароли в открытом репозитории
git add config/secrets.json   # API ключи в git

# После push — секрет НАВСЕГДА в истории, даже после удаления файла
# Нужно менять все ключи и пароли

# Правильно:
echo ".env" >> .gitignore
echo "*.pem" >> .gitignore
echo "credentials.*" >> .gitignore
# Используй: git-secrets, truffleHog, gitleaks для сканирования
```

### Force push на main
```bash
# Уничтожает чужую работу:
git push -f origin main  # 3 дня работы коллеги — потеряны

# Правильно:
# Защита main branch в GitHub/GitLab
# Merge через Pull Request
# Rebase на своей ветке, merge в main
```

### Огромные коммиты
```bash
# Говнокодинг:
git add .
git commit -m "update"  # 50 файлов, 3 фичи, 2 багфикса в одном коммите
                         # невозможно ревьювить, невозможно откатить одну фичу

# Правильно:
git add handler/auth.go service/auth.go
git commit -m "feat: add Telegram auth verification"

git add handler/practice.go
git commit -m "fix: handle empty problem list in practice mode"
```

### Отсутствие CI/CD
```
Без CI/CD:
1. Пишешь код
2. "У меня работает"
3. Push в main
4. Прод сломался
5. 3 часа дебага

С CI/CD:
1. Пишешь код
2. Push → автоматически: lint, test, build
3. PR не мержится пока CI зелёный
4. Auto-deploy в staging → ручная проверка → deploy в прод
```

### Как избежать
- `.gitignore` с первого коммита. Шаблоны: gitignore.io
- Branch protection: main только через PR
- CI/CD минимум: `lint` + `test` + `build` на каждый PR
- Маленькие коммиты с понятными сообщениями
- `git-secrets` или `gitleaks` в pre-commit hook

---

## Чеклист: прогони перед каждым коммитом

### ИИ-специфичное
```
□ Все пакеты/зависимости существуют и проверены
□ Все API/методы реально существуют в документации
□ Я понимаю каждую строку которую коммичу
□ Не больше 2-3 итераций на один кусок кода
```

### Безопасность
```
□ Нет SQL без параметризации
□ Нет innerHTML с пользовательским вводом
□ Нет секретов в коде (пароли, токены, ключи)
□ .gitignore содержит .env, *.pem, credentials.*
□ Auth endpoints под rate limiting
```

### Качество кода
```
□ Ошибки не глотаются (нет catch-all, нет _ = err)
□ Edge cases: null, пустой массив, 0, отрицательные числа
□ Нет дублирования с существующим кодом проекта
□ Нет магических чисел — все значения в const
□ Код в правильном слое (handler/service/repository)
□ Функции < 30 строк, вложенность < 3 уровней
□ Имена переменных и функций понятны без контекста
```

### Тесты и CI
```
□ Тесты покрывают не только happy path
□ Тесты на поведение, а не на реализацию
□ Нет time.Sleep в тестах
□ Линтер/анализатор прошёл без ошибок
□ go test -race ./... (для Go)
```

### Git
```
□ Коммит содержит одно логическое изменение
□ Сообщение коммита описывает "почему", а не "что"
□ Нет .env или секретов в staged файлах
```

---

## Цифры для запоминания

### ИИ-специфичное
| Метрика | Значение |
|---------|----------|
| Багов в ИИ-коде vs человеческого | **1.7x больше** |
| XSS уязвимости в ИИ-коде | **2.74x больше** |
| Логические ошибки в ИИ-коде | **1.75x больше** |
| Галлюцинированные пакеты | **20% рекомендаций** |
| Выдуманные API | **30% рекомендаций** |
| ИИ-код с OWASP уязвимостями | **45%** |
| Ухудшение после 5 итераций | **+37% уязвимостей** |
| Разработчики не ревьювящие ИИ-код | **52%** |

### Говнокодинг в целом
| Метрика | Значение |
|---------|----------|
| Стоимость плохого софта (США/год) | **$2.41 трлн** (CISQ 2024) |
| IT бюджеты на техдолг | **40%** (McKinsey) |
| Время девов на техдолг | **33%** (Stripe 2023) |
| Техдолг на 1000 строк кода | **$3,700-$6,000** (CAST) |
| Код который скопирован | **70%** (GitHub) |
| Клоны кода с дефектами | **17%** (CP-Miner) |
| Новых CVE в день (2025) | **133** |
| Пентесты с exploitable misconfigs | **80%** (Rapid7) |
| Cloud инциденты от человеческих ошибок | **82%** |
| Ускорение нахождения багов при хороших именах | **+14%** |
| Memory safety баги от всех критичных | **~70%** (Chromium) |
| Замедление фич при высоком техдолге | **25-50%** |

---

## Источники

### ИИ-специфичные
- [CodeRabbit: AI vs Human Code Report](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report) — 1.7x больше багов
- [Stack Overflow: Bugs with AI Agents](https://stackoverflow.blog/2026/01/28/are-bugs-and-incidents-inevitable-with-ai-coding-agents) — итеративная деградация
- [Addy Osmani: The 80% Problem](https://addyo.substack.com/p/the-80-problem-in-agentic-coding) — проблема последних 20%
- [Clutch: Blind Trust in AI Code](https://clutch.co/resources/devs-use-ai-generated-code-they-dont-understand) — comprehension debt
- [IEEE Spectrum: AI Coding Degrades](https://spectrum.ieee.org/ai-coding-degrades) — silent failures
- [The Register: AI Code Bugs](https://www.theregister.com/2025/12/17/ai_code_bugs/) — статистика уязвимостей
- [BleepingComputer: Slopsquatting](https://www.bleepingcomputer.com/news/security/ai-hallucinated-code-dependencies-become-new-supply-chain-risk/) — галлюцинации пакетов
- [Palo Alto Unit42: Vibe Coding Security](https://unit42.paloaltonetworks.com/securing-vibe-coding-tools/) — 69 уязвимостей в vibe coding
- [Simon Willison: Hallucinations in Code](https://simonwillison.net/2025/Mar/2/hallucinations-in-code/) — выдуманные API
- [OX Security Report](https://www.prnewswire.com/news-releases/ox-report-ai-generated-code-violates-engineering-best-practices-undermining-software-security-at-scale-302592642.html) — нарушение best practices
- [GitClear: AI Code Quality 2025](https://www.gitclear.com/ai_assistant_code_quality_2025_research) — code churn и клоны

### Говнокодинг в целом
- [CISQ: Cost of Poor Software Quality 2024](https://www.it-cisq.org/the-cost-of-poor-quality-software-in-the-us-a-2022-report/) — $2.41 трлн
- [McKinsey: Breaking Technical Debt's Vicious Cycle](https://www.mckinsey.com/capabilities/mckinsey-digital/our-insights/breaking-technical-debts-vicious-cycle-to-modernize-your-business) — 40% IT бюджетов
- [Stripe Developer Coefficient 2023](https://stripe.com/resources/more/the-developer-coefficient) — 33% времени на техдолг
- [CAST: Software Intelligence](https://www.castsoftware.com/) — $3,700-$6,000 на 1000 строк
- [Google DORA 2024 Report](https://services.google.com/fh/files/misc/2024_final_dora_report.pdf) — метрики стабильности
- [SANS/CWE Top 25 2025](https://cwe.mitre.org/top25/archive/2025/2025_cwe_top25.html) — XSS #1, SQLi #2
- [Rapid7: Penetration Testing Report](https://www.rapid7.com/) — 80% exploitable misconfigs
- [Chromium Memory Safety](https://www.chromium.org/Home/chromium-security/memory-safety/) — 70% критичных багов
- [CP-Miner: Copy-Paste Bugs](https://people.cs.uchicago.edu/~shanlu/paper/TSE-CPMiner.pdf) — 70% кода скопировано, 17% клонов с багами
- [University of Hawaii: Identifier Naming](https://scholarspace.manoa.hawaii.edu/bitstreams/f49497a1-7a9f-49dd-b707-51d8a054662a/download) — 14% быстрее с хорошими именами
- [Martin Fowler: Code Smells](https://martinfowler.com/bliki/CodeSmell.html) — таксономия code smells
- [Robert C. Martin: Clean Code](https://www.oreilly.com/library/view/clean-code-a/9780136083238/) — принципы чистого кода
