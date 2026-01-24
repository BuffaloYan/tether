class Contact {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final int priority; // 1, 2, or 3

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.priority,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      priority: json['priority'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'priority': priority,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      priority: map['priority'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'priority': priority,
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    int? priority,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() {
    return 'Contact(name: $name, phone: $phone, priority: $priority)';
  }
}
