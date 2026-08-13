class ContainerModel {
  final String id;
  final String name;
  final String image;
  final String status;
  final String created;
  final String ports;

  ContainerModel({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.created,
    required this.ports,
  });

  // Factory pour créer une instance à partir d'un objet JSON décodé
  factory ContainerModel.fromJson(Map<String, dynamic> json) {
    return ContainerModel(
      id: json['ID'] ?? json['Id'] ?? '',
      name: json['Names'] ?? json['Name'] ?? '',
      image: json['Image'] ?? '',
      status: json['Status'] ?? '',
      created: json['CreatedAt'] ?? json['Created'] ?? '',
      ports: json['Ports'] ?? '',
    );
  }

  // Convertir l'instance en Map JSON (utile pour le stockage local ou le debug)
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Names': name,
      'Image': image,
      'Status': status,
      'CreatedAt': created,
      'Ports': ports,
    };
  }

  // Vérifier rapidement si le conteneur est en cours d'exécution
  bool get isRunning => status.toLowerCase().startsWith('up');
}