use shared::Message;

#[tokio::main]
async fn main() {
    println!("🍏 [Mac Daemon] Démarrage de l'agent d'orchestration...");
    
    // Test bidon pour vérifier que le module 'shared' est bien importé
    let msg = Message::Ping;
    println!("Message de test prêt : {:?}", msg);
    
    // Ici viendra le serveur WebSocket plus tard
    println!("✅ Démon prêt en attente de la Surface !");
}