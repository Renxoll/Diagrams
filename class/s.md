Para la Capa de Dominio (C02):

“Se definió [AggregateRootName] como raíz del agregado porque, según el sitio web evaluado en la sección [Nombre de la sección], la entidad controla de manera exclusiva el ciclo de vida de [AssociatedEntityName].”

“[ValueObjectName] se modeló como Value Object debido a que no requiere identidad propia y representa un atributo compuesto e inmutable según el requerimiento de [especificar lógica del negocio del examen].”

Para la Capa de Aplicación (C04):

“El método handle en [FeatureName]ApplicationService recibe un [ActionName]Command para asegurar que los datos de entrada provengan desacoplados del protocolo de transporte (HTTP/REST), cumpliendo con el flujo de transacciones para [caso específico del sitio web].”

“El servicio de aplicación no ejecuta reglas de negocio directas, sino que recupera el agregado mediante [AggregateName]Repository, delega la acción al dominio y persiste el estado, cumpliendo la separación de responsabilidades.”
