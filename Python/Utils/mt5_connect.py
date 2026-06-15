import MetaTrader5 as mt5

def test_connection():
    print("Initialize MT5 connection...")
    
    # Path to terminal.exe (if mt5 fails to find it, we can provide it, but usually it finds the active one)
    # The user's MT5 is located at C:\Users\golde\AppData\Roaming\MetaQuotes\Terminal\4B1CE69F577705455263BD980C39A82C
    # but the exe is usually in C:\Program Files\ICMarkets MT5 Terminal\terminal64.exe or similar.
    # We will try the default initialization first.
    if not mt5.initialize():
        print("initialize() failed, error code =", mt5.last_error())
        quit()
        
    account_id = 52916915
    password = "6BA4$AlL6YEstr"
    server = "ICMarketsEU-Demo"
    
    print(f"Trying to login to account {account_id} on {server}...")
    
    authorized = mt5.login(account_id, password=password, server=server)
    if authorized:
        print(f"Successfully logged in to account: {account_id}")
    else:
        print(f"Login failed, error code: {mt5.last_error()}")

    # Request terminal info
    terminal_info = mt5.terminal_info()
    if terminal_info != None:
        print("\n--- MT5 Terminal Info ---")
        print(f"Connected: {terminal_info.connected}")
        print(f"Trade Allowed: {terminal_info.trade_allowed}")
        print(f"Version: {mt5.version()}")
        
    # Get account info
    account_info = mt5.account_info()
    if account_info != None:
        print("\n--- Account Info ---")
        print(f"Login: {account_info.login}")
        print(f"Balance: {account_info.balance} {account_info.currency}")
        print(f"Equity: {account_info.equity}")
        print(f"Server: {account_info.server}")
    else:
        print("Failed to get account info")

    # Shut down connection
    mt5.shutdown()
    print("MT5 connection closed.")

if __name__ == "__main__":
    test_connection()
