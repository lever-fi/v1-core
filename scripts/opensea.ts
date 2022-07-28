import { ethers } from "hardhat";

async function main() {
  // deploy nft
  const purchaseAgent = await ethers.getContractAt(
    "PurchaseAgent",
    "0xc6d95cA5cc00902D1EbB152d4E5dfe857FbeF0D5"
  );

  const data = ethers.utils.AbiCoder.prototype.encode(
    [
      "tuple(address, uint256, uint256, address, address, address, uint256, uint256, uint8, uint256, uint256, bytes32, uint256, bytes32, bytes32, uint256, tuple(uint256, address)[], bytes), uint256",
    ],
    [
      [
        "0x0000000000000000000000000000000000000000", // consideration token
        ethers.BigNumber.from("0"), // consideration identifier
        ethers.BigNumber.from("2"), // consideration amount
        "0x6e84150012fd6d571c33c266424fcdecf80e3274", // offerer
        "0x00000000E88FE2628EbC5DA81d2b3CeaD633E89e", // zone
        "0x5CD3A8b0842c29f5FaaAF09a990B61e24FD68bb8", // collection address
        ethers.BigNumber.from(56), // token id
        ethers.BigNumber.from(1), // collection amount
        ethers.BigNumber.from(3), // order type
        ethers.BigNumber.from("1659009620"), // start time
        ethers.BigNumber.from("1661688020"), // end time
        "0x0000000000000000000000000000000000000000000000000000000000000000", // zone hash
        ethers.BigNumber.from("83829219237913258"), // salt
        "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000", // offerer conduit key
        "0x0000000000000000000000000000000000000000000000000000000000000000", // fulfiller conduit key
        ethers.BigNumber.from("2"), // original additional recipients
        [
          [
            ethers.BigNumber.from("195000000000000000"), // amount
            "0x6E84150012Fd6D571C33C266424fcDEcF80E3274", // recipient
          ],
          [
            ethers.BigNumber.from("5000000000000000"), // amount
            "0x8De9C5A032463C561423387a9648c5C7BCC5BC90", // recipient
          ],
        ],
        "0xd82ad34b643eeb16a49d9b5b2b92aea10423b579357d1ee03feedf88745352007760dd23bd050ff3d279cb199e7bf93095d65d369b2c8400be6cc95fc09e71671c", // signature
      ],
      ethers.utils.parseEther("0.2"),
    ]
  );

  purchaseAgent.purchase(1, data, {
    value: ethers.utils.parseEther("0.2"),
    //gasLimit: 100000,
  });
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

const d = {
  next: null,
  previous: null,
  orders: [
    {
      created_date: "2022-07-28T12:00:33.129429",
      closing_date: "2022-08-28T12:00:20",
      listing_time: 1659009620,
      expiration_time: 1661688020,
      order_hash:
        "0x4d0893d7a778f9f6c5d7629ae02b849748605310657c5bec9631f133f801f8c6",
      protocol_data: {
        parameters: {
          offerer: "0x6e84150012fd6d571c33c266424fcdecf80e3274",
          offer: [
            {
              itemType: 2,
              token: "0x5CD3A8b0842c29f5FaaAF09a990B61e24FD68bb8",
              identifierOrCriteria: "56",
              startAmount: "1",
              endAmount: "1",
            },
          ],
          consideration: [
            {
              itemType: 0,
              token: "0x0000000000000000000000000000000000000000",
              identifierOrCriteria: "0",
              startAmount: "195000000000000000",
              endAmount: "195000000000000000",
              recipient: "0x6E84150012Fd6D571C33C266424fcDEcF80E3274",
            },
            {
              itemType: 0,
              token: "0x0000000000000000000000000000000000000000",
              identifierOrCriteria: "0",
              startAmount: "5000000000000000",
              endAmount: "5000000000000000",
              recipient: "0x8De9C5A032463C561423387a9648c5C7BCC5BC90",
            },
          ],
          startTime: "1659009620",
          endTime: "1661688020",
          orderType: 2,
          zone: "0x00000000E88FE2628EbC5DA81d2b3CeaD633E89e",
          zoneHash:
            "0x0000000000000000000000000000000000000000000000000000000000000000",
          salt: "83829219237913258",
          conduitKey:
            "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
          totalOriginalConsiderationItems: 2,
          counter: 0,
        },
        signature:
          "0xd82ad34b643eeb16a49d9b5b2b92aea10423b579357d1ee03feedf88745352007760dd23bd050ff3d279cb199e7bf93095d65d369b2c8400be6cc95fc09e71671c",
      },
      protocol_address: "0x00000000006c3852cbef3e08e8df289169ede581",
      maker: {
        user: 151844,
        profile_img_url:
          "https://storage.googleapis.com/opensea-static/opensea-profile/2.png",
        address: "0x6e84150012fd6d571c33c266424fcdecf80e3274",
        config: "",
      },
      taker: null,
      current_price: "200000000000000000",
      maker_fees: [
        {
          account: {
            user: null,
            profile_img_url:
              "https://storage.googleapis.com/opensea-static/opensea-profile/31.png",
            address: "0x8de9c5a032463c561423387a9648c5c7bcc5bc90",
            config: "",
          },
          basis_points: "250",
        },
      ],
      taker_fees: [],
      side: "ask",
      order_type: "basic",
      cancelled: false,
      finalized: false,
      marked_invalid: true,
      client_signature:
        "0xd82ad34b643eeb16a49d9b5b2b92aea10423b579357d1ee03feedf88745352007760dd23bd050ff3d279cb199e7bf93095d65d369b2c8400be6cc95fc09e71671c",
      relay_id: "T3JkZXJWMlR5cGU6NzkxMTQ0",
      criteria_proof: null,
      maker_asset_bundle: {
        assets: [
          {
            id: 70586783,
            num_sales: 0,
            background_color: null,
            image_url:
              "https://lh3.googleusercontent.com/WzE5d__JnJ7x6LNFDK8wZF2ucxRTm0FU1ChZfUQqKAQPVYnEKd87Q6E58G3dvIQJVY4YnE6JEaNM7s8T4cFGm3aLxJAQ4Pt785op",
            image_preview_url:
              "https://lh3.googleusercontent.com/WzE5d__JnJ7x6LNFDK8wZF2ucxRTm0FU1ChZfUQqKAQPVYnEKd87Q6E58G3dvIQJVY4YnE6JEaNM7s8T4cFGm3aLxJAQ4Pt785op=s250",
            image_thumbnail_url:
              "https://lh3.googleusercontent.com/WzE5d__JnJ7x6LNFDK8wZF2ucxRTm0FU1ChZfUQqKAQPVYnEKd87Q6E58G3dvIQJVY4YnE6JEaNM7s8T4cFGm3aLxJAQ4Pt785op=s128",
            image_original_url:
              "https://opensea.mypinata.cloud/ipfs/QmcT3DKumXjLDWtpA4MAk4ad5NLitpsRFJjNxK7qHERPw8",
            animation_url: null,
            animation_original_url: null,
            name: "Eagle",
            description: "This is an flying eagle",
            external_link: null,
            asset_contract: {
              address: "0x5cd3a8b0842c29f5faaaf09a990b61e24fd68bb8",
              asset_contract_type: "non-fungible",
              created_date: "2022-06-08T16:47:39.237658",
              name: "MyNFT",
              nft_version: null,
              opensea_version: null,
              owner: 8614161,
              schema_name: "ERC721",
              symbol: "NFT",
              total_supply: null,
              description: null,
              external_link: null,
              image_url: null,
              default_to_fiat: false,
              dev_buyer_fee_basis_points: 0,
              dev_seller_fee_basis_points: 0,
              only_proxied_transfers: false,
              opensea_buyer_fee_basis_points: 0,
              opensea_seller_fee_basis_points: 250,
              buyer_fee_basis_points: 0,
              seller_fee_basis_points: 250,
              payout_address: null,
            },
            permalink:
              "https://testnets.opensea.io/assets/rinkeby/0x5cd3a8b0842c29f5faaaf09a990b61e24fd68bb8/56",
            collection: {
              banner_image_url: null,
              chat_url: null,
              created_date: "2022-06-08T17:04:46.313166",
              default_to_fiat: false,
              description: null,
              dev_buyer_fee_basis_points: "0",
              dev_seller_fee_basis_points: "0",
              discord_url: null,
              display_data: {
                card_display_style: "contain",
                images: [],
              },
              external_url: null,
              featured: false,
              featured_image_url: null,
              hidden: false,
              safelist_request_status: "not_requested",
              image_url: null,
              is_subject_to_whitelist: false,
              large_image_url: null,
              medium_username: null,
              name: "MyNFT - ctOsgOKnaX",
              only_proxied_transfers: false,
              opensea_buyer_fee_basis_points: "0",
              opensea_seller_fee_basis_points: "250",
              payout_address: null,
              require_email: false,
              short_description: null,
              slug: "mynft-ctosgoknax",
              telegram_url: null,
              twitter_username: null,
              instagram_username: null,
              wiki_url: null,
              is_nsfw: false,
            },
            decimals: null,
            token_metadata:
              "https://opensea.mypinata.cloud/ipfs/QmToasrqQ54v7Xvorp3HJPJ7Us73Xrq5CrkV1eyq1Gbur8",
            is_nsfw: false,
            owner: {
              user: {
                username: null,
              },
              profile_img_url:
                "https://storage.googleapis.com/opensea-static/opensea-profile/2.png",
              address: "0x6e84150012fd6d571c33c266424fcdecf80e3274",
              config: "",
            },
            token_id: "56",
          },
        ],
        maker: null,
        slug: null,
        name: null,
        description: null,
        external_link: null,
        asset_contract: {
          collection: {
            banner_image_url: null,
            chat_url: null,
            created_date: "2022-06-08T17:04:46.313166",
            default_to_fiat: false,
            description: null,
            dev_buyer_fee_basis_points: "0",
            dev_seller_fee_basis_points: "0",
            discord_url: null,
            display_data: {
              card_display_style: "contain",
              images: [],
            },
            external_url: null,
            featured: false,
            featured_image_url: null,
            hidden: false,
            safelist_request_status: "not_requested",
            image_url: null,
            is_subject_to_whitelist: false,
            large_image_url: null,
            medium_username: null,
            name: "MyNFT - ctOsgOKnaX",
            only_proxied_transfers: false,
            opensea_buyer_fee_basis_points: "0",
            opensea_seller_fee_basis_points: "250",
            payout_address: null,
            require_email: false,
            short_description: null,
            slug: "mynft-ctosgoknax",
            telegram_url: null,
            twitter_username: null,
            instagram_username: null,
            wiki_url: null,
            is_nsfw: false,
          },
          address: "0x5cd3a8b0842c29f5faaaf09a990b61e24fd68bb8",
          asset_contract_type: "non-fungible",
          created_date: "2022-06-08T16:47:39.237658",
          name: "MyNFT",
          nft_version: null,
          opensea_version: null,
          owner: 8614161,
          schema_name: "ERC721",
          symbol: "NFT",
          total_supply: null,
          description: null,
          external_link: null,
          image_url: null,
          default_to_fiat: false,
          dev_buyer_fee_basis_points: 0,
          dev_seller_fee_basis_points: 0,
          only_proxied_transfers: false,
          opensea_buyer_fee_basis_points: 0,
          opensea_seller_fee_basis_points: 250,
          buyer_fee_basis_points: 0,
          seller_fee_basis_points: 250,
          payout_address: null,
        },
        permalink: "https://testnets.opensea.io/bundles/None",
        sell_orders: null,
        seaport_sell_orders: null,
      },
      taker_asset_bundle: {
        assets: [
          {
            id: 382494,
            num_sales: 0,
            background_color: null,
            image_url:
              "https://openseauserdata.com/files/6f8e2979d428180222796ff4a33ab929.svg",
            image_preview_url: null,
            image_thumbnail_url: null,
            image_original_url: null,
            animation_url: null,
            animation_original_url: null,
            name: null,
            description: null,
            external_link: null,
            asset_contract: {
              address: "0x0000000000000000000000000000000000000000",
              asset_contract_type: "fungible",
              created_date: "2019-08-02T22:08:33.341923",
              name: "Ether",
              nft_version: null,
              opensea_version: null,
              owner: null,
              schema_name: "ERC20",
              symbol: "",
              total_supply: null,
              description: "",
              external_link: null,
              image_url: null,
              default_to_fiat: false,
              dev_buyer_fee_basis_points: 0,
              dev_seller_fee_basis_points: 0,
              only_proxied_transfers: false,
              opensea_buyer_fee_basis_points: 0,
              opensea_seller_fee_basis_points: 250,
              buyer_fee_basis_points: 0,
              seller_fee_basis_points: 250,
              payout_address: null,
            },
            permalink:
              "https://testnets.opensea.io/assets/rinkeby/0x0000000000000000000000000000000000000000/0",
            collection: {
              banner_image_url: null,
              chat_url: null,
              created_date: "2019-08-02T22:08:33.340525",
              default_to_fiat: false,
              description: "",
              dev_buyer_fee_basis_points: "0",
              dev_seller_fee_basis_points: "0",
              discord_url: null,
              display_data: {},
              external_url: null,
              featured: false,
              featured_image_url: null,
              hidden: false,
              safelist_request_status: "approved",
              image_url: null,
              is_subject_to_whitelist: false,
              large_image_url: null,
              medium_username: null,
              name: "Ether",
              only_proxied_transfers: false,
              opensea_buyer_fee_basis_points: "0",
              opensea_seller_fee_basis_points: "250",
              payout_address: null,
              require_email: false,
              short_description: null,
              slug: "ether",
              telegram_url: null,
              twitter_username: null,
              instagram_username: null,
              wiki_url: null,
              is_nsfw: false,
            },
            decimals: 18,
            token_metadata: null,
            is_nsfw: false,
            owner: {
              user: {
                username: "NullAddress",
              },
              profile_img_url:
                "https://storage.googleapis.com/opensea-static/opensea-profile/1.png",
              address: "0x0000000000000000000000000000000000000000",
              config: "",
            },
            token_id: "0",
          },
        ],
        maker: null,
        slug: null,
        name: "ETH - None",
        description: null,
        external_link: null,
        asset_contract: {
          collection: {
            banner_image_url: null,
            chat_url: null,
            created_date: "2019-08-02T22:08:33.340525",
            default_to_fiat: false,
            description: "",
            dev_buyer_fee_basis_points: "0",
            dev_seller_fee_basis_points: "0",
            discord_url: null,
            display_data: {},
            external_url: null,
            featured: false,
            featured_image_url: null,
            hidden: false,
            safelist_request_status: "approved",
            image_url: null,
            is_subject_to_whitelist: false,
            large_image_url: null,
            medium_username: null,
            name: "Ether",
            only_proxied_transfers: false,
            opensea_buyer_fee_basis_points: "0",
            opensea_seller_fee_basis_points: "250",
            payout_address: null,
            require_email: false,
            short_description: null,
            slug: "ether",
            telegram_url: null,
            twitter_username: null,
            instagram_username: null,
            wiki_url: null,
            is_nsfw: false,
          },
          address: "0x0000000000000000000000000000000000000000",
          asset_contract_type: "fungible",
          created_date: "2019-08-02T22:08:33.341923",
          name: "Ether",
          nft_version: null,
          opensea_version: null,
          owner: null,
          schema_name: "ERC20",
          symbol: "",
          total_supply: null,
          description: "",
          external_link: null,
          image_url: null,
          default_to_fiat: false,
          dev_buyer_fee_basis_points: 0,
          dev_seller_fee_basis_points: 0,
          only_proxied_transfers: false,
          opensea_buyer_fee_basis_points: 0,
          opensea_seller_fee_basis_points: 250,
          buyer_fee_basis_points: 0,
          seller_fee_basis_points: 250,
          payout_address: null,
        },
        permalink: "https://testnets.opensea.io/bundles/None",
        sell_orders: null,
        seaport_sell_orders: null,
      },
    },
  ],
};
