# OneWord - Repositório de Projeto, Arquitetura de Hardware & iOS

Bem-vindo ao repositório do projeto **OneWord**.

Este ambiente consolida a documentação técnica oficial cobrindo desde os **mecanismos físicos, cinemática e ciência de materiais do hardware da Apple** até a **arquitetura de desenvolvimento de software no ecossistema iOS/Swift**.

---

## 📚 Documentação Técnica do Projeto

### 1. [Tratado de Mecanismos Físicos e Engenharia de Hardware Apple](file:///Users/rogerioduraes/Documents/dev/OneWord/docs/APPLE_HARDWARE_PHYSICAL_MECHANISMS.md)
Documentação técnica e física dos mecanismos e ferramentas do ecossistema Apple:
- **Transdução Eletromecânica & Háptica:** *Taptic Engine*, Linear Resonant Actuators (LRA), molas de lâmina plana e frenagem ativa anti-fase (*active braking*).
- **Sensoriamento de Força e Deformação Estrutural:** *Force Touch*, pontes de Wheatstone (*strain gauges* piezoelétricas) e células de carga nos cantos de trackpads de vidro.
- **Botão de Controle de Câmera (*Camera Control* - iPhone 16):** Módulo híbrido trifásico unindo safira condutiva multitoque capacitiva, sensor piezorresistivo de meia-pressão (*light press*) e microswitch mecânico de aço inoxidável.
- **Ferramentas Ativas de Precisão (*Apple Pencil 1/2/Pro*):** Transdutor piezoelétrico na ponta (4.096 níveis de pressão), emissores eletrostáticos coaxiais de ângulo/tilt (\(\theta, \phi\)), giroscópio MEMS de rotação de barril (*barrel roll*), sensores de compressão (*squeeze*) e carregamento indutivo por campo eletromagnético.
- **Codificadores Rotativos e Biometria Físico-Óptica:** *Digital Crown* (encoders ópticos de fendas com fotodiodos em quadratura e eletrodo de biopotencial galvânico para ECG), *Touch ID* (RF capacitivo) e *Face ID TrueDepth* (laser VCSEL e matriz difrativa de 30.000 pontos).
- **Acoplamento Magnético de Alta Densidade:** Matrizes de *Halbach* circulares (*MagSafe*), cancelamento de fluxo parasita interno e pinos *Pogo* carregados por mola de berílio-cobre com banho de ouro galvânico (*Smart Connector*).
- **Cinemática de Teclados e Dobradiças:** Mecanismo de tesoura (*scissor switch*) com domo de silicone elastômero, dobradiças de fricção balanceada com embreagem axial no MacBook (*one-finger open*) e braço bi-articulado cantilever flutuante do *Magic Keyboard*.
- **Microtecnologia MEMS e Sensores Espaciais:** Pentes capacitivos diferenciais (acelerômetros/giroscópios por efeito Coriolis), barômetros piezorresistivos com cavidade de vácuo, e *LiDAR Scanner dToF* com matrizes SPAD.
- **Engenharia de Materiais & Termodinâmica:** Titânio Grau 5 fundido por difusão de estado sólido, vidro vitrocerâmico *Ceramic Shield*, câmaras de vapor bifásicas de cobre sinterizado e pás de ventilador com espaçamento angular assimétrico para atenuação aeroacústica.

---

### 2. [Guia Completo e Referência de APIs iOS](file:///Users/rogerioduraes/Documents/dev/OneWord/IOS_DEVELOPER_REFERENCE.md)
Documentação técnica de desenvolvimento de software e integração:
- **Linguagem & Concorrência:** Swift 6, `async/await`, `actor`, `Sendable`, `TaskGroup`.
- **Interface & UI:** SwiftUI declarativo, `@Observable`, `NavigationStack`, animações com `PhaseAnimator`.
- **Arquitetura:** MVVM, Injeção de Dependências e desacoplamento com protocolos.
- **Persistência de Dados:** SwiftData (`@Model`, `@Query`), Keychain Services seguro, `UserDefaults`.
- **Rede & Conectividade:** `URLSession` moderna, `Network.framework`, WebSockets.
- **Hardware & Sensores:** AVFoundation (câmera/áudio), MapKit, CoreLocation, Haptics nativos.
- **IA & Machine Learning:** Apple Intelligence, CoreML, Vision Framework (OCR).
- **Integração com iOS:** Live Activities, Dynamic Island, WidgetKit, App Intents (Siri & Atalhos).
- **Acesso & Gratuito:** 100% Gratuito e Ilimitado (todos os recursos de neuroleitura, IA e eye-tracking liberados sem assinaturas ou paywalls).
- **Testes & Qualidade:** Novo framework `Swift Testing` (`@Test`, `#expect`), lista de chaves de permissão `Info.plist`.

---

### 3. [Engenharia de Baterias do iPhone & Otimização de Energia no iOS](file:///Users/rogerioduraes/Documents/dev/OneWord/IPHONE_BATTERY_AND_POWER_OPTIMIZATION.md)
Tratado técnico de eletroquímica e arquitetura de software adaptativa de energia:
- **Eletroquímica de Li-ion/Li-Po:** Formação e crescimento da camada SEI (*Solid Electrolyte Interphase*), degradação de ciclos (500 a 1000 ciclos), *lithium plating* e faixas térmicas críticas.
- **Impedância & Queda de Tensão (*Voltage Sag*):** Modelagem de $V_{\text{terminal}} = V_{\text{OCV}} - (I \times R)$ e prevenção de desligamentos inesperados (*brownout protection*).
- **Firmware & Proteções Apple:** Carregamento Otimizado com ML, limite de 80% (iPhone 15/16+), gerenciamento dinâmico de desempenho e controle térmico de MagSafe/USB-PD.
- **Topologia Apple Silicon:** Princípio *Race-to-Sleep*, alocação de núcleos P-Cores vs. E-Cores via *Quality of Service*, aceleração na Neural Engine (ANE) e telas OLED/ProMotion.
- **Rádios & Modem Celular:** Máquina de estados RRC (IDLE, CONNECTED, TAIL STATES) e custos do *keep-alive churn*.
- **APIs Nativas & Frameworks:** `UIDevice` battery monitoring, `ProcessInfo` (Low Power Mode & Thermal States), `BackgroundTasks` (`BGTaskScheduler`), `URLSession` discricionário e telemetria de campo com `MetricKit`.
- **Arquitetura Adaptativa de Software:** Implementação completa de `PowerManager` reativo em Swift 6 e matriz de perfis energéticos dinâmicos (`Optimal`, `Balanced`, `Conservative`, `CriticalEco`).
- **Auditoria & Profiling:** Xcode Instruments (*Energy Log*), Developer Mode HUD e checklist rigoroso de certificação energética para release.

---

### 4. [Extensão Google Chrome & Conector RSVP](file:///Users/rogerioduraes/Documents/dev/OneWord/chrome-extension/README.md)
Extensão oficial Manifest V3 para leitura dinâmica web e conector nativo:
- **Conector Nativo (`oneword://`):** Envia artigos e seleções da web diretamente para o app OneWord no macOS/iOS.
- **Leitor RSVP Integrado:** Leitor foveal com guias ORP em vermelho, ritmo inteligente, controle de 150 a 900+ WPM e temas (Dark, Light, Sépia).
- **Popup & Side Panel:** Suporte ao painel lateral do Chrome para leitura paralela à navegação.
- **Menu de Contexto & Atalhos:** Leitura imediata com clique direito ou atalhos de teclado (`Alt+Shift+O`, `Alt+Shift+W`).

---

## 🚀 Como Utilizar

Consulte os arquivos de referência conforme a necessidade:
- Para projetos e features que demandam modelagem física, periféricos, latência mecânica, calibração de sensores ou design tátil: acesse [`APPLE_HARDWARE_PHYSICAL_MECHANISMS.md`](file:///Users/rogerioduraes/Documents/dev/OneWord/docs/APPLE_HARDWARE_PHYSICAL_MECHANISMS.md).
- Para implementação de código Swift, UI, persistência e arquitetura de software: consulte [`IOS_DEVELOPER_REFERENCE.md`](file:///Users/rogerioduraes/Documents/dev/OneWord/IOS_DEVELOPER_REFERENCE.md).
- Para otimização de consumo de energia, gestão de bateria, perfil térmico e telemetria: consulte [`IPHONE_BATTERY_AND_POWER_OPTIMIZATION.md`](file:///Users/rogerioduraes/Documents/dev/OneWord/IPHONE_BATTERY_AND_POWER_OPTIMIZATION.md).
- Para instalar e testar a extensão no navegador Chrome: consulte [`chrome-extension/README.md`](file:///Users/rogerioduraes/Documents/dev/OneWord/chrome-extension/README.md).

