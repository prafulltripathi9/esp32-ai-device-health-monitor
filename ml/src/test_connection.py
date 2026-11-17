from data_loader import fetch_telemetry

def main():
    print("Connecting to MariaDB...")

    try:
        df = fetch_telemetry("ESP32_001")

        print("\nDatabase connection successful!")
        print(f"Total records fetched: {len(df)}")

        print("\nLatest 5 telemetry records:")
        print(df.tail(5).to_string(index=False))

    except Exception as error:
        print("\nDatabase connection failed!")
        print(error)


if __name__ == "__main__":
    main()