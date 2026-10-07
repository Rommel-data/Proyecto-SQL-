![Sales Analytics](./Picture/baneer%20vertical.png)
# Proyecto SQL: Análisis de Car Sales - Ticket promedio, margen y tasa de descuento

## Resumen (Overview)
_El personal de recursos humanos de **GreatPlaceToWork** desea mejorar el desempeño, aumentar la retención y mejorar la satisfacción laboral general. Sin embargo, no cuentan con una visión clara de los datos pertinentes de los empleados. Mi objetivo es utilizar **SQL** dentro de **SQL Server Management Studio**, analizando sus datos para proporcionar recomendaciones al departamento de RR.HH. que faciliten mejoras exitosas._

## 📩 Si quieres aprender SQL Conéctate conmigo
<p align="center">
  <a href="https://www.linkedin.com/in/jhon-velasque/">
    <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white" />
  </a>
  <a href="https://www.youtube.com/@HOLAMeDicenJHON">
    <img src="https://img.shields.io/badge/YouTube-FF0000?style=flat-square&logo=youtube&logoColor=white" />
  </a>
  <a href="https://www.instagram.com/hola_me_dicen_jhon/">
    <img src="https://img.shields.io/badge/Instagram-E4405F?style=flat-square&logo=instagram&logoColor=white" />
  </a>
  <a href="https://www.tiktok.com/@medicenjhon0?is_from_webapp=1&sender_device=pc">
    <img src="https://img.shields.io/badge/TikTok-000000?style=flat-square&logo=tiktok&logoColor=white" />
  </a>
  <a href="https://wa.link/kzegye">
    <img src="https://img.shields.io/badge/WhatsApp-25D366?style=flat-square&logo=whatsapp&logoColor=white" />
  </a>
</p>

## Estructura del Proyecto

- [Sobre los Datos](#sobre-los-datos)
- [Tareas](#tareas)
- [Limpieza de Datos](#limpieza-de-datos)
- [Análisis Exploratorio de Datos e Insights](#análisis-exploratorio-de-datos-e-insights)

## Sobre los Datos

Los datos originales, junto con una explicación de cada columna, se pueden encontrar [aquí](https://www.kaggle.com/datasets/mahmoudemadabdallah/hr-analytics-employee-attrition-and-performance/data?select=Employee.csv).

El conjunto de datos incluye cinco tablas que capturan evaluaciones de desempeño, datos demográficos de los empleados, niveles de satisfacción y calificaciones, distribuidos en más de 8,100 registros y 40 columnas.

![HR Analytics](./picture/muestra_tabla_employe.png)

## Tareas (Task)

En este análisis, ayudo al departamento de RR.HH. a responder lo siguiente:

1. **Antigüedad:** ¿Cuál es el promedio de antigüedad de los empleados en cada departamento?
2. **Retención:** ¿Cuántos empleados en cada departamento siguen trabajando actualmente en la empresa?
3. **Satisfacción vs. Antigüedad:** ¿Cómo se compara la satisfacción laboral de los empleados en diferentes niveles de antigüedad?
4. **Horas Extras:** ¿Qué porcentaje de empleados que trabajan horas extras han dejado la empresa?
5. **Desempeño por Viajes:** Clasificar los departamentos por el promedio de calificación de los gerentes, desglosado por frecuencia de viajes de negocios.
6. **Capacitación:** ¿Existe una correlación positiva entre el número de oportunidades de capacitación tomadas y la satisfacción laboral?
7. **Talento Top:** Identificar a los tres mejores empleados según la calificación de su gerente en cada departamento.
8. **Distancia al Trabajo:** Categorizar a los empleados según su distancia al trabajo y mostrar el promedio de satisfacción laboral en cada categoría.
9. **Promociones y Liderazgo:** ¿Existe una relación entre el número de ascensos y los años que un empleado ha pasado con su gerente actual?
10. **Alerta de Rotación:** Para cada departamento, identificar el porcentaje de empleados que se han ido y que tenían una puntuación de satisfacción laboral inferior a 3.

## Limpieza de Datos

Antes de realizar el análisis, es fundamental asegurar que los datos estén limpios y listos. Dado que las tablas `EducationLevel`, `RatingLevel` y `SatisfiedLevel` son de referencia, el trabajo principal se centra en las tablas `Employee` y `PerformanceRating`.

#### Valores Nulos o Faltantes

Primero, verifiqué la existencia de valores faltantes en los dos campos clave: `EmployeeID` y `PerformanceID`. No se encontraron valores nulos.

```sql
-- Verificar valores faltantes en la tabla Employee --

SELECT COUNT(*) AS MissingValues
FROM Employee
WHERE EmployeeID IS NULL;

--Verificar valores faltantes en la tabla PerformanceRating--

SELECT COUNT(*) AS MissingValues
FROM PerformanceRating
WHERE PerformanceID IS NULL
    OR EmployeeID IS NULL;
```

A continuación, es vital asegurarse de que se eliminen las filas duplicadas, en caso de encontrarse, nuevamente en los campos clave. No se encontraron duplicados.

```sql
-- Verificar valores duplicados en la tabla Employe --

SELECT EmployeeID, COUNT(*)
FROM Employee
GROUP BY EmployeeID
HAVING COUNT(*) > 1;

-- Verificar valores duplicados en la tabla PerformanceRating --

SELECT PerformanceID, COUNT(*)
FROM PerformanceRating
GROUP BY PerformanceID
HAVING COUNT(*) > 1;
```


## Análisis Exploratorio de Datos (EDA) e Insights


### Conclusion

- Este análisis proporcionó información importante sobre las áreas donde GreatPlaceToWork puede mejorar la experiencia del empleado.

- Uno de los descubrimientos principales fue la alta tasa de rotación entre los trabajadores que realizan horas extras.

- Se detectaron niveles de satisfacción variables dependiendo de la distancia que el empleado recorre desde su hogar al trabajo.

- Para abordar estos problemas, la empresa debe tomar la iniciativa y enfocarse en mejorar los esfuerzos de retención.Es fundamental fortalecer el apoyo que brindan los gerentes a sus equipos.Resulta vital continuar desarrollando y expandiendo los programas de capacitación internos.
