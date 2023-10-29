import os
import json
import pandas as pd
from web3 import Web3
from pathlib import Path
from dotenv import load_dotenv
import streamlit as st
from streamlit_extras.no_default_selectbox import selectbox
from io import StringIO
#from pinata import pin_file_to_ipfs, pin_json_to_ipfs, convert_data_to_json

# Load environment variables
load_dotenv()

# Connect to Web3 provider
w3 = Web3(Web3.HTTPProvider(os.getenv("WEB3_PROVIDER_URI")))

# Load the contract
@st.cache_resource()
def load_contract():
    #Load verification Contract
    with open(Path('./ABI_files/verificationV3.json')) as f:
        verfication_abi = json.load(f)
    
    #Load CreateToken Contract 
    with open(Path('./ABI_files/RealEstateTokenV3.json')) as f:
        createToken_abi = json.load(f)
    contract_address = os.getenv("SMART_CONTRACT_ADDRESS")
    return w3.eth.contract(address=contract_address, abi=createToken_abi), w3.eth.contract(address=contract_address, abi=verfication_abi)

create_token_contract, verification_contract = load_contract()

# Helper functions for pinning
# def pin_house_data(name, file):
#     ipfs_file_hash = pin_file_to_ipfs(file.getvalue())
#     token_json = {
#         "name": name,
#         "image": ipfs_file_hash
#     }
#     json_data = convert_data_to_json(token_json)
#     json_ipfs_hash = pin_json_to_ipfs(json_data)
#     return json_ipfs_hash, token_json


# Main Streamlit UI

# with st.container():
#    st.write("As a User you hereby accept the terms and conditions of this application, allowing Escrow to be incharge")

#    # You can call any Streamlit command, including custom components:
#    if st.button("Accept"):
#     st.write("Thank you for accepting the terms and conditions")
st.title("Decentralized Real Estate App")    
tab1, tab2 = st.tabs(["Seller", "Buyer"])
with tab1:
    st.title("Registration System")
    st.write("Choose an account to get started")
    accounts = w3.eth.accounts
    address = st.selectbox("Select Account", options=accounts, key = "address")
    st.markdown("---")

    # step1: Add the property
    st.markdown("## Add Property")
    uploaded_deed = st.file_uploader("Upload Deed")
    if uploaded_deed is not None:
        # To convert to a string based IO:
        if 'deedhash' not in st.session_state:
            st.session_state.deedhash = None
        st.session_state.deedhash = StringIO(uploaded_deed.getvalue().decode("utf-8")) 
        
    if 'verification_status' not in st.session_state:
        st.session_state.verification_status = False
    if 'property_id' not in st.session_state:
        st.session_state.property_id = 0
    if st.button("Add Property"):
        st.write(st.session_state.deedhash.getvalue())
        st.session_state.property_id = verification_contract.events.PropertyAdded(st.session_state.deedhash.getvalue())#.transact({"from": w3.eth.accounts[0]})           
        #receipt = w3.eth.waitForTransactionReceipt(property_id)
        # step2: Verify property
    if st.button("Verify Property"):
        #st.session_state.verification_status = verification_contract.functions.verifyProperty(int(st.session_state.property_id)).transact({'from': address, 'gas': 1000000})
        if st.session_state.property_id!= None:
            st.write("Property Verfied! Please Register Property")
        else:
            st.write("Invalid Property.Please Add Property!")      
    
    Property_Type = ("RESIDENTIAL", "COMMERCIAL","AGRICULTURAL","OTHER")
    Building_Type= ("DETACHED", "SEMI_DETACHED", "ROW_HOUSE",  "CONDO","OTHER")
    parking_Type = ("GARAGE",  "DRIVEWAY", "STREET", "OTHER")
    propType_len = list(range(len(Property_Type)))
    buildType_len = list(range(len(Building_Type)))
    parkType_len = list(range(len(parking_Type)))

    # step3: Register/Add the Property
    st.markdown("## Register Property")
    property_id = st.session_state.property_id
    description = st.text_input("Enter the description of the property")
    location = st.text_input("Enter the property address")
    price = st.text_input("Enter the price")
    imageHash = st.text_input("Enter the image")
    propertyType = st.selectbox("Property Type", options= propType_len, format_func=lambda x: Property_Type[x], key = "propType")
    buildingType = st.selectbox("Building Type", options= buildType_len,format_func=lambda x: Building_Type[x], key="buildType")        
    storeys = st.text_input("Enter the no. of storeys of the property")
    landSize = st.text_input("Enter the Land Size")
    propertyTaxes = st.text_input("Enter the Property Taxes")
    parkingType = st.selectbox("Parking Type", options= parkType_len,format_func=lambda x: parking_Type[x], key = "parkType")
        
    if st.button("Register Property"):       
        token_id = create_token_contract.functions.createOrDetailedRealEstateToken(
            property_id,
            description,         
            location,          
            int(price),             
            imageHash, 
            propertyType,      
            buildingType,
            int(storeys),       
            int(landSize),             
            int(propertyTaxes),
            parkingType     
        ).transact({'from': address, 'gas': 1000000})
        
        receipt = w3.eth.waitForTransactionReceipt(token_id)
        st.write("Transaction receipt mined:")
        st.write(dict(receipt))
        # st.markdown(f"[Property IPFS Gateway Link](https://ipfs.io/ipfs/{house_ipfs_hash})")
        # st.markdown(f"[Property IPFS Image Link](https://ipfs.io/ipfs/{token_json['image']})")

    st.markdown("---")

with tab2:
    
    st.title("Real Estate Marketplace")
    st.write("Choose an account to get started")
    accounts = w3.eth.accounts
    address = st.selectbox("Select Account", options=accounts)
    st.markdown("---")

# Fetch total number of properties/tokens
total_properties = create_token_contract.functions.totalSupply().call()
property_ids = list(range(total_properties))
df = pd.DataFrame(property_ids, columns=("Property ID"))
st.table(df)

# Property Details
st.markdown("## Select Property Id to check the property details")
property_id = st.selectbox("Choose a Property ID", property_ids)

if st.button("Check Property"):
    property_json = create_token_contract.functions.viewRealEstate(property_id).call()

    st.markdown("## Property Details")
    st.write(property_json)