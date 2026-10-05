# 🌐 Domain Monitor & API Status Platform

Plataforma SaaS de alta eficiencia para la monitorización en tiempo real de dominios web, certificados SSL y endpoints API RESTful.

Desarrollada con **Ruby on Rails 8**, optimizada para despliegues en contenedores e infraestructura de coste cero en la nube (Heroku-24 Stack).

---

## 🚀 Características Principales

* **Monitorización Atómica Concurrente:** Comprobación periódica automatizada y disparadores manuales instantáneos (*Check Status Now*) con medición de latencia en milisegundos.
* **Procesamiento en Memoria (Zero-Cost Storage):** Generación y descarga de informes de disponibilidad CSV generados al vuelo en memoria RAM (`send_data`), evitando persistencia en disco o almacenamiento redundante en base de datos.
* **Motor de Retención Automatizado:** Tareas programadas en segundo plano con `SolidQueue` (`CleanupDatabaseJob`) para purgar históricos antiguos y respetar los límites de bases de datos gratuitas.
* **Arquitectura Multi-Tier (Free vs. PRO):** Validación estricta de cuotas en modelo y controlador con banners y bloqueos en interfaz gráfica.
* **Página de Estado Pública Unificada:** Estado operativo global (`/status`) y páginas individuales (`/status/:token`) accesibles sin autenticación.
* **Servidor de Aplicación Puma 8:** Configuración de concurrencia optimizada para Ruby 3.3.

---

## 🛠️ Stack Tecnológico

* **Framework:** Ruby on Rails 8.0.x
* **Lenguaje:** Ruby 3.3.x
* **Base de Datos:** PostgreSQL
* **Background Jobs:** Solid Queue
* **Frontend:** Tailwind CSS, Turbo, Stimulus
* **Servidor Web:** Puma 8

---

## 👥 Cuentas de Demostración

| Perfil | Email | Contraseña | Límite |
| :--- | :--- | :--- | :--- |
| **Free Tier** | `demo-free@monitor.com` | `Password123!` | 3 monitores |
| **Admin / PRO** | `admin@monitor.com` | `Password123!` | Hasta 50 monitores |

---

## 📄 Licencia

Proyecto desarrollado con fines académicos.
