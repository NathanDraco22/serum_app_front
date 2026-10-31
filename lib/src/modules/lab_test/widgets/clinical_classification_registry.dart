class ClinicalClassificationRegistry {
  static const Map<String, List<String>> categoriesWithSubclassifications = {
    'Hematología': [
      'Serie Roja',
      'Serie Blanca',
      'Serie Plaquetaria / Coagulación',
      'Frotis Sanguíneo',
      'General',
    ],
    'Química Sanguínea': [
      'Perfil Lipídico',
      'Función Renal',
      'Función Hepática',
      'Electrolitos Séricos',
      'Carbohidratos / Glucosa',
      'Enzimas Cardíacas / Pancreáticas',
      'Proteínas Totales y Fraccionadas',
      'General',
    ],
    'Bioquímica Clínica': [
      'Perfil Lipídico',
      'Función Renal',
      'Función Hepática',
      'Electrolitos Séricos',
      'Carbohidratos / Glucosa',
      'Enzimas Cardíacas / Pancreáticas',
      'Proteínas Totales y Fraccionadas',
      'General',
    ],
    'Uroanálisis': [
      'Examen Físico-Químico',
      'Sedimento Microscópico',
      'General',
    ],
    'Coprología': [
      'Examen Macroscópico',
      'Examen Microscópico',
      'Parasitología',
      'Sangre Oculta',
      'General',
    ],
    'Inmunología': [
      'Pruebas Rápidas',
      'Marcadores Infecciosos',
      'Marcadores Tumorales',
      'Enfermedades Autoinmunes',
      'General',
    ],
    'Serología': [
      'Pruebas Rápidas',
      'Marcadores Infecciosos',
      'Reacciones Febriles',
      'General',
    ],
    'Endocrinología / Hormonas': [
      'Perfil Tiroideo',
      'Hormonas Reproductivas / Fertilidad',
      'Otras Hormonas',
      'General',
    ],
    'Microbiología': [
      'Cultivos y Antibiogramas',
      'Tinciones',
      'Exudados',
      'General',
    ],
    'Electrolitos': [
      'Electrolitos Séricos',
      'Electrolitos en Orina',
      'General',
    ],
    'Pruebas Especiales': [
      'Toxicología',
      'Drogas de Abuso',
      'Biología Molecular',
      'General',
    ],
  };

  static List<String> get classifications {
    final list = categoriesWithSubclassifications.keys.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  static List<String> getSubclassificationsFor(String classification) {
    if (classification.trim().isEmpty) return ['General'];
    
    // Buscar coincidencia exacta o por subcadena
    for (final entry in categoriesWithSubclassifications.entries) {
      if (entry.key.toLowerCase() == classification.trim().toLowerCase()) {
        final subs = List<String>.from(entry.value);
        subs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return subs;
      }
    }

    for (final entry in categoriesWithSubclassifications.entries) {
      if (classification.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(classification.toLowerCase())) {
        final subs = List<String>.from(entry.value);
        subs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return subs;
      }
    }

    return ['General'];
  }
}
